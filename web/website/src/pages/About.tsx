import './About.css'

function About() {
  return (
    <div className="about-page">
      <section className="about-hero">
        <p className="eyebrow">Our mission</p>
        <h1>Friendships shouldn't<br />fade by accident</h1>
        <p className="about-intro">
          We built Friendly because we believe the most meaningful part of life
          is the people in it. Yet in our busy, always-connected world, the
          relationships that matter most are often the first to slip through the
          cracks.
        </p>
      </section>

      <section className="about-content">
        <div className="about-card">
          <h2>Why Friendly exists</h2>
          <p>
            Most apps fight for your attention. Friendly fights for your
            relationships. We're not a social network — there's no feed, no
            likes, no public profiles. Friendly is a private, personal tool
            that helps you show up for the people who matter.
          </p>
          <p>
            Whether it's a childhood best friend across the country or a
            colleague you keep meaning to grab coffee with, Friendly makes
            sure the intent to connect turns into action.
          </p>
        </div>

        <div className="about-card">
          <h2>Our principles</h2>
          <div className="principles-grid">
            <div className="principle">
              <h3>🔒 Privacy first</h3>
              <p>
                Your relationships are deeply personal. We never sell your data,
                and we design every feature with privacy as the foundation.
              </p>
            </div>
            <div className="principle">
              <h3>🌿 Gentle by design</h3>
              <p>
                No guilt trips, no gamification tricks. Friendly uses kind
                nudges that respect your time and energy.
              </p>
            </div>
            <div className="principle">
              <h3>🎯 Intentional</h3>
              <p>
                Every feature exists to help you be more present in your
                relationships. If it doesn't serve that goal, we don't build it.
              </p>
            </div>
            <div className="principle">
              <h3>💛 Human-centered</h3>
              <p>
                Technology should enhance human connection, not replace it.
                Friendly gets out of your way so you can focus on people.
              </p>
            </div>
          </div>
        </div>

        <div className="about-card">
          <h2>Get in touch</h2>
          <p>
            We'd love to hear from you. Whether you have feedback, questions,
            or just want to say hello:
          </p>
          <p>
            <strong>Email:</strong>{' '}
            <a href="mailto:hello@bemorefriendly.com">hello@bemorefriendly.com</a>
          </p>
        </div>
      </section>
    </div>
  )
}

export default About
