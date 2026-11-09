from copy import deepcopy
from datetime import datetime, timedelta, timezone
import hashlib
from pathlib import Path
import runpy
import unittest


validator = runpy.run_path(str(Path(__file__).resolve().parents[1] / "scripts/check-profiles.py"))
TEAM = validator["TEAM"]
DRIVER = validator["BUNDLE_ID"] + ".driver"
ACCESS = "com.apple.developer.driverkit.userclient-access"


class ReleaseProfileTests(unittest.TestCase):
    def setUp(self):
        self.bundle = validator["BUNDLE_ID"] + ".agent"
        self.now = datetime(2026, 11, 9, tzinfo=timezone.utc)
        self.certificate = b"fixture certificate"
        self.profile = {
            "TeamIdentifier": [TEAM],
            "ApplicationIdentifierPrefix": [TEAM],
            "ExpirationDate": self.now + timedelta(days=1),
            "DeveloperCertificates": [self.certificate],
            "ProvisionsAllDevices": True,
            "Entitlements": {
                "com.apple.application-identifier": f"{TEAM}.{self.bundle}",
                ACCESS: [DRIVER],
            },
        }

    def errors(self, profile):
        return validator["profile_errors"](
            profile, self.bundle, {ACCESS: [DRIVER]},
            hashlib.sha1(self.certificate).hexdigest(), self.now,
        )

    def test_matching_profile(self):
        self.assertEqual(self.errors(self.profile), [])

    def test_profile_may_allow_more_than_signature_claims(self):
        self.profile["Entitlements"][ACCESS] = ["*"]
        self.assertEqual(self.errors(self.profile), [])

    def test_wrong_app_cannot_sign_agent(self):
        self.profile["Entitlements"]["com.apple.application-identifier"] = f"{TEAM}.*"
        self.assertIn("expected explicit App ID", " ".join(self.errors(self.profile)))

    def test_wrong_driver_is_rejected(self):
        self.profile["Entitlements"][ACCESS] = ["com.example.other.driver"]
        self.assertIn(f"missing authorization for {ACCESS}", self.errors(self.profile))

    def test_expired_development_and_wrong_certificate_are_rejected(self):
        invalid = deepcopy(self.profile)
        invalid["ExpirationDate"] = self.now - timedelta(days=1)
        invalid["ProvisionsAllDevices"] = False
        invalid["DeveloperCertificates"] = [b"other certificate"]
        self.assertEqual(len(self.errors(invalid)), 3)


if __name__ == "__main__":
    unittest.main()
