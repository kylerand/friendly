import './Legal.css'

function Terms() {
  return (
    <div className="legal-page">
      <div className="legal-header">
        <p className="eyebrow">Legal</p>
        <h1>Terms of Service</h1>
        <p className="legal-updated">Last updated: February 14, 2026</p>
      </div>

      <div className="legal-body">
        <section>
          <h2>Agreement to Terms</h2>
          <p>
            By accessing or using Friendly (the "Service"), you agree to be
            bound by these Terms of Service ("Terms"). If you do not agree to
            these Terms, you may not use the Service.
          </p>
        </section>

        <section>
          <h2>Description of Service</h2>
          <p>
            Friendly is a relationship wellness application that helps users
            maintain and strengthen personal connections through reminders,
            check-ins, interaction tracking, and connection insights. The
            Service is provided via a mobile application and supporting web
            services.
          </p>
        </section>

        <section>
          <h2>Eligibility</h2>
          <p>
            You must be at least 13 years of age to use the Service. By using
            the Service, you represent and warrant that you meet this
            requirement and have the legal capacity to enter into these Terms.
          </p>
        </section>

        <section>
          <h2>User Accounts</h2>
          <p>
            To use certain features of the Service, you must create an account.
            You are responsible for maintaining the confidentiality of your
            account credentials and for all activity that occurs under your
            account. You agree to notify us immediately of any unauthorized use.
          </p>
        </section>

        <section>
          <h2>Acceptable Use</h2>
          <p>You agree not to:</p>
          <ul>
            <li>Use the Service for any unlawful purpose</li>
            <li>Harass, abuse, or harm other users</li>
            <li>Attempt to gain unauthorized access to the Service or its systems</li>
            <li>Interfere with or disrupt the Service</li>
            <li>Upload malicious code or content</li>
            <li>Impersonate any person or entity</li>
            <li>Use automated means to access the Service without our permission</li>
          </ul>
        </section>

        <section>
          <h2>Intellectual Property</h2>
          <p>
            The Service and its original content, features, and functionality
            are owned by Friendly and are protected by copyright, trademark, and
            other intellectual property laws. You may not reproduce, distribute,
            or create derivative works without our prior written consent.
          </p>
        </section>

        <section>
          <h2>User Content</h2>
          <p>
            You retain ownership of any content you submit to the Service
            (such as notes, interaction descriptions, and profile information).
            By submitting content, you grant us a limited license to store,
            process, and display it as necessary to provide the Service.
          </p>
        </section>

        <section>
          <h2>Termination</h2>
          <p>
            We may suspend or terminate your access to the Service at any time,
            with or without cause, and with or without notice. You may delete
            your account at any time. Upon termination, your right to use the
            Service ceases immediately.
          </p>
        </section>

        <section>
          <h2>Disclaimer of Warranties</h2>
          <p>
            The Service is provided "as is" and "as available" without
            warranties of any kind, whether express or implied, including but
            not limited to implied warranties of merchantability, fitness for a
            particular purpose, and non-infringement.
          </p>
        </section>

        <section>
          <h2>Limitation of Liability</h2>
          <p>
            To the fullest extent permitted by law, Friendly shall not be liable
            for any indirect, incidental, special, consequential, or punitive
            damages, or any loss of profits or data, arising out of or in
            connection with your use of the Service.
          </p>
        </section>

        <section>
          <h2>Changes to Terms</h2>
          <p>
            We reserve the right to modify these Terms at any time. We will
            provide notice of material changes by posting the updated Terms on
            this page. Your continued use of the Service after changes
            constitutes acceptance of the revised Terms.
          </p>
        </section>

        <section>
          <h2>Governing Law</h2>
          <p>
            These Terms shall be governed by and construed in accordance with
            the laws of the United States, without regard to conflict of law
            principles.
          </p>
        </section>

        <section>
          <h2>Contact Us</h2>
          <p>
            If you have questions about these Terms, please contact us at:
          </p>
          <p>
            <strong>Email:</strong>{' '}
            <a href="mailto:legal@bemorefriendly.com">legal@bemorefriendly.com</a>
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

export default Terms
