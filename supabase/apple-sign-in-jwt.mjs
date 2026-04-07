import fs from "fs";
import jwt from "jsonwebtoken";

const TEAM_ID = "9EPVM358CS";
const KEY_ID = "Z6498Z7LXU";
const CLIENT_ID = "com.kylerand.friendly"; // <-- CHANGE to your exact Bundle ID
const P8_PATH = "AuthKey_Z6498Z7LXU.p8"; // <-- CHANGE to your .p8 filename/path

const privateKey = fs.readFileSync(P8_PATH, "utf8");

const now = Math.floor(Date.now() / 1000);

// Apple allows up to 6 months (15777000 seconds) for exp.
// I usually do 180 days.
const token = jwt.sign(
  {
    iss: TEAM_ID,
    iat: now,
    exp: now + 60 * 60 * 24 * 180,
    aud: "https://appleid.apple.com",
    sub: CLIENT_ID,
  },
  privateKey,
  {
    algorithm: "ES256",
    keyid: KEY_ID,
  }
);

console.log(token);