#!/usr/bin/env python3
"""Find and validate the Developer ID profiles used by SplitArc."""

import argparse
from datetime import datetime, timezone
import fnmatch
import hashlib
from pathlib import Path
import plistlib
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
TEAM = "6KV8L8WQ9D"
IDENTITY = f"Developer ID Application: Alessio Cosi ({TEAM})"
BUNDLE_ID = "dev.icosisenpai.splitarc"
TARGETS = {
    "app": (BUNDLE_ID, "SplitArcApp/SplitArc.entitlements"),
    "agent": (BUNDLE_ID + ".agent", "SplitArcAgent/SplitArcAgent.entitlements"),
    "driver": (BUNDLE_ID + ".driver", "VirtualJoyConDriver/VirtualJoyConDriver.entitlements"),
}


def signing_certificate(identity):
    if not identity.startswith("Developer ID Application:") or not identity.endswith(f"({TEAM})"):
        raise ValueError(f"Use a Developer ID Application certificate for team {TEAM}.")
    identities = subprocess.check_output(["security", "find-identity", "-v", "-p", "codesigning"], text=True)
    for fingerprint, name in re.findall(r'([A-Fa-f0-9]{40}) "([^"]+)"', identities):
        if name == identity:
            return fingerprint.lower()
    raise ValueError("The selected signing certificate is unavailable in Keychain.")


def matches_entitlement(requested, allowed):
    if isinstance(requested, list):
        return isinstance(allowed, list) and all(
            any(isinstance(pattern, str) and fnmatch.fnmatchcase(value, pattern) for pattern in allowed)
            for value in requested
        )
    return type(allowed) is type(requested) and allowed == requested


def app_id(profile):
    entitlements = profile.get("Entitlements", {})
    return entitlements.get("com.apple.application-identifier") or entitlements.get("application-identifier", "")


def profile_errors(profile, bundle, required, certificate, now):
    entitlements = profile.get("Entitlements", {})
    prefixes = profile.get("ApplicationIdentifierPrefix", [])
    errors = []
    if TEAM not in profile.get("TeamIdentifier", []):
        errors.append(f"expected team {TEAM}")
    if app_id(profile) not in {f"{prefix}.{bundle}" for prefix in prefixes}:
        errors.append(f"expected explicit App ID {bundle}")
    expiration = profile.get("ExpirationDate")
    if not isinstance(expiration, datetime) or expiration.replace(tzinfo=timezone.utc) <= now:
        errors.append("profile has expired or is missing an expiration date")
    if profile.get("ProvisionsAllDevices") is not True or entitlements.get("get-task-allow"):
        errors.append("expected a Developer ID distribution profile")
    if not any(hashlib.sha1(der).hexdigest() == certificate for der in profile.get("DeveloperCertificates", [])):
        errors.append("profile does not authorize the selected Developer ID certificate")
    for key, value in required.items():
        if not matches_entitlement(value, entitlements.get(key)):
            errors.append(f"missing authorization for {key}")
    return errors


def decode_profile(path):
    decoded = subprocess.check_output(["security", "cms", "-D", "-i", str(path)], stderr=subprocess.DEVNULL)
    return plistlib.loads(decoded)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--identity", default=IDENTITY)
    parser.add_argument("--directory", action="append", type=Path, default=[])
    parser.add_argument("--manifest", type=Path)
    for role in TARGETS:
        parser.add_argument(f"--{role}", type=Path)
    args = parser.parse_args()

    try:
        certificate = signing_certificate(args.identity)
    except (ValueError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1

    paths = set()
    for directory in [
        Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
        Path.home() / "Library/MobileDevice/Provisioning Profiles",
        *args.directory,
    ]:
        paths.update(directory.expanduser().glob("*.provisionprofile"))
    explicit = {role: getattr(args, role) for role in TARGETS}
    paths.update(path.expanduser() for path in explicit.values() if path)

    decoded = {}
    for path in sorted(paths):
        try:
            decoded[path] = decode_profile(path)
        except (subprocess.CalledProcessError, ValueError, plistlib.InvalidFileException):
            continue

    now = datetime.now(timezone.utc)
    manifest = {}
    for role, (bundle, entitlement_path) in TARGETS.items():
        required = plistlib.loads((ROOT / entitlement_path).read_bytes())
        supplied = explicit[role]
        candidates = [supplied.expanduser()] if supplied else [
            path for path, profile in decoded.items() if app_id(profile).endswith(f".{bundle}")
        ]
        valid = []
        for path in candidates:
            if path not in decoded:
                print(f"{bundle}: cannot read {path}", file=sys.stderr)
                continue
            profile = decoded[path]
            errors = profile_errors(profile, bundle, required, certificate, now)
            if errors:
                print(f"{bundle} ({path.name}): {'; '.join(errors)}", file=sys.stderr)
            else:
                valid.append((profile["ExpirationDate"], path))

        if valid:
            selected = max(valid)[1].resolve()
            manifest[role] = str(selected)
            print(f"{bundle}: {selected.name}")
        else:
            print(f"{bundle}: no usable Developer ID profile", file=sys.stderr)

    if len(manifest) != len(TARGETS):
        return 1
    if args.manifest:
        args.manifest.write_bytes(plistlib.dumps(manifest))
    return 0


if __name__ == "__main__":
    sys.exit(main())
