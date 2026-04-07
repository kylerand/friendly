import './Home.css'

function Home() {
  return (
    <div className="home">
      <section className="hero">
        <div className="hero-halo" />
        <p className="eyebrow">Relationship wellness</p>
        <h1>Stay close to the<br />people who matter</h1>
        <p className="hero-sub">
          Friendly helps you nurture your most important relationships with
          gentle reminders, meaningful check-ins, and connection insights —
          so no one drifts away.
        </p>
        <div className="hero-cta">
          <a href="https://apps.apple.com" className="btn btn-primary" target="_blank" rel="noopener noreferrer">
            Download for iOS
          </a>
          <a href="#features" className="btn btn-secondary">See how it works</a>
        </div>
      </section>

      <section className="features" id="features">
        <h2>Built for real friendships</h2>
        <p className="section-sub">
          Not another social network. Friendly is a private, personal tool that
          keeps your relationships healthy.
        </p>
        <div className="feature-grid">
          <div className="feature-card">
            <div className="feature-icon">🤝</div>
            <h3>Smart check-ins</h3>
            <p>
              Get gentle nudges when it's been a while since you connected with
              someone important. Never let a friendship fade by accident.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">📊</div>
            <h3>Connection insights</h3>
            <p>
              See how your relationships are doing at a glance. Understand
              patterns and invest your time where it counts.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🔒</div>
            <h3>Completely private</h3>
            <p>
              Your relationship data stays on your device and in your secure
              account. We never sell or share your personal information.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">✨</div>
            <h3>Effortless tracking</h3>
            <p>
              Ambient signals and smart detection mean less manual logging.
              Friendly works quietly in the background.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">💬</div>
            <h3>Interaction history</h3>
            <p>
              Keep a lightweight journal of meaningful moments — a lunch,
              a call, a thoughtful message — so you remember what matters.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">🌱</div>
            <h3>Friendship growth</h3>
            <p>
              Watch your connections strengthen over time. Friendly celebrates
              consistency and helps you build lasting bonds.
            </p>
          </div>
        </div>
      </section>

      <section className="cta-section">
        <div className="cta-card">
          <h2>Ready to be more friendly?</h2>
          <p>
            Join people who are intentional about their relationships.
            Download Friendly and start strengthening your connections today.
          </p>
          <a href="https://apps.apple.com" className="btn btn-primary" target="_blank" rel="noopener noreferrer">
            Get Friendly — It's Free
          </a>
        </div>
      </section>
    </div>
  )
}

export default Home
