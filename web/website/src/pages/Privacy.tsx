import './Legal.css'

function Privacy() {
  return (
    <div className="legal-page">
      <div className="legal-header">
        <p className="eyebrow">Legal</p>
        <h1>Privacy Policy</h1>
        <p className="legal-updated">Last updated: February 14, 2026</p>
      </div>

      <div className="legal-body">
        <section>
          <h2>Introduction</h2>
          <p>
            Friendly ("we", "our", or "us") is committed to protecting your
            privacy. This Privacy Policy explains how we collect, use, disclose,
            and safeguard your information when you use our mobile application
            and related services (collectively, the "Service").
          </p>
          <p>
            By using the Service, you agree to the collection and use of
            information in accordance with this policy. If you do not agree with
            this policy, please do not use the Service.
          </p>
        </section>

        <section>
          <h2>Information We Collect</h2>
          <h3>Account Information</h3>
          <p>
            When you create an account, we collect your email address or phone
            number and a display name. This information is used to identify your
            account and enable core app functionality.
          </p>

          <h3>Relationship Data</h3>
          <p>
            Friendly stores information about your connections, check-ins,
            interaction history, and friendship status. This data is central to
            the Service and is used to provide you with reminders and insights.
          </p>

          <h3>Device Information</h3>
          <p>
            We may collect device identifiers, operating system version, and app
            version to provide support, ensure compatibility, and improve the
            Service.
          </p>

          <h3>Ambient Signals</h3>
          <p>
            With your explicit permission, Friendly may collect ambient signals
            (such as proximity or interaction frequency) to help reduce manual
            logging. This data is processed locally or stored securely in your
            account and is never shared with third parties.
          </p>
        </section>

        <section>
          <h2>How We Use Your Information</h2>
          <ul>
            <li>To provide, maintain, and improve the Service</li>
            <li>To send you check-in reminders and connection insights</li>
            <li>To provide customer support</li>
            <li>To detect and prevent fraud or abuse</li>
            <li>To comply with legal obligations</li>
          </ul>
        </section>

        <section>
          <h2>Data Sharing &amp; Disclosure</h2>
          <p>
            We do <strong>not</strong> sell, rent, or trade your personal
            information. We may share information only in the following
            circumstances:
          </p>
          <ul>
            <li>
              <strong>With your consent:</strong> When you explicitly authorize
              sharing, such as connecting with a friend on the platform.
            </li>
            <li>
              <strong>Service providers:</strong> We use trusted third-party
              services (such as cloud hosting and authentication) that process
              data on our behalf under strict confidentiality agreements.
            </li>
            <li>
              <strong>Legal requirements:</strong> We may disclose information
              if required by law or to protect the safety and rights of our
              users.
            </li>
          </ul>
        </section>

        <section>
          <h2>Data Security</h2>
          <p>
            We implement industry-standard security measures including
            encryption in transit (TLS) and at rest, row-level security policies,
            and regular security audits. However, no method of electronic
            transmission or storage is 100% secure, and we cannot guarantee
            absolute security.
          </p>
        </section>

        <section>
          <h2>Data Retention</h2>
          <p>
            We retain your personal data for as long as your account is active
            or as needed to provide the Service. You may request deletion of your
            account and associated data at any time by contacting us.
          </p>
        </section>

        <section>
          <h2>Your Rights</h2>
          <p>Depending on your jurisdiction, you may have the right to:</p>
          <ul>
            <li>Access the personal data we hold about you</li>
            <li>Request correction of inaccurate data</li>
            <li>Request deletion of your data</li>
            <li>Object to or restrict processing of your data</li>
            <li>Request portability of your data</li>
          </ul>
          <p>
            To exercise any of these rights, please contact us at the address
            below.
          </p>
        </section>

        <section>
          <h2>Children's Privacy</h2>
          <p>
            The Service is not intended for children under the age of 13. We do
            not knowingly collect personal information from children under 13. If
            we become aware that we have collected data from a child under 13,
            we will take steps to delete it promptly.
          </p>
        </section>

        <section>
          <h2>Changes to This Policy</h2>
          <p>
            We may update this Privacy Policy from time to time. We will notify
            you of any material changes by posting the new policy on this page
            and updating the "Last updated" date. Your continued use of the
            Service after changes constitutes acceptance of the revised policy.
          </p>
        </section>

        <section>
          <h2>Contact Us</h2>
          <p>
            If you have questions or concerns about this Privacy Policy, please
            contact us at:
          </p>
          <p>
            <strong>Email:</strong>{' '}
            <a href="mailto:privacy@bemorefriendly.com">privacy@bemorefriendly.com</a>
          </p>
          <p>
            <strong>Website:</strong>{' '}
            <a href="https://bemorefriendly.com">https://bemorefriendly.com</a>
          </p>
        </section>
      </div>
    </div>
  )
}

export default Privacy
