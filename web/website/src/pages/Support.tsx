import './Legal.css'

function Support() {
  return (
    <div className="legal-page">
      <div className="legal-header">
        <p className="eyebrow">Help</p>
        <h1>Support</h1>
        <p className="legal-updated">We're here to help you get the most out of Friendly.</p>
      </div>

      <div className="legal-body">
        <section>
          <h2>Frequently Asked Questions</h2>

          <h3>What is Friendly?</h3>
          <p>
            Friendly is a relationship wellness app that helps you stay
            connected with the people who matter most. It provides gentle
            reminders, check-in tracking, and insights to help you nurture
            your friendships.
          </p>

          <h3>Is Friendly free?</h3>
          <p>
            Yes! Friendly is free to download and use. We may introduce
            optional premium features in the future, but the core experience
            will always be free.
          </p>

          <h3>Is my data private?</h3>
          <p>
            Absolutely. Your relationship data is stored securely and is never
            sold or shared with third parties. See our{' '}
            <a href="/privacy">Privacy Policy</a> for full details.
          </p>

          <h3>How do check-in reminders work?</h3>
          <p>
            Friendly tracks how long it's been since you connected with each
            person and sends gentle reminders when someone might be drifting.
            You can customize reminder frequency for each connection.
          </p>

          <h3>Can I delete my account?</h3>
          <p>
            Yes. You can request account deletion at any time, and all your
            data will be permanently removed from our systems.
          </p>
        </section>

        <section>
          <h2>Contact Support</h2>
          <p>
            Can't find what you're looking for? We'd love to help.
          </p>
          <p>
            <strong>Email:</strong>{' '}
            <a href="mailto:support@bemorefriendly.com">support@bemorefriendly.com</a>
          </p>
          <p>
            We aim to respond within 24 hours on business days.
          </p>
        </section>

        <section>
          <h2>Report a Bug</h2>
          <p>
            Found something that doesn't look right? Please let us know by
            emailing{' '}
            <a href="mailto:support@bemorefriendly.com">support@bemorefriendly.com</a>{' '}
            with a description of the issue, your device type, and the app
            version. Screenshots are always helpful!
          </p>
        </section>
      </div>
    </div>
  )
}

export default Support
