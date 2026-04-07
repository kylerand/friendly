import { Link, Outlet, useLocation } from 'react-router-dom'
import { useEffect } from 'react'
import logo from './assets/friendly_logo_color.png'
import './Layout.css'

function Layout() {
  const { pathname } = useLocation()

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [pathname])

  return (
    <div className="site">
      <nav className="navbar">
        <Link to="/" className="nav-brand">
          <img src={logo} alt="Friendly" className="nav-logo" />
          <span className="nav-wordmark">Friendly</span>
        </Link>
        <div className="nav-links">
          <Link to="/about">About</Link>
          <Link to="/support">Support</Link>
          <Link to="/privacy">Privacy</Link>
        </div>
      </nav>

      <main>
        <Outlet />
      </main>

      <footer className="footer">
        <div className="footer-inner">
          <div className="footer-brand">
            <img src={logo} alt="Friendly" className="footer-logo" />
            <p>Stay close to the people who matter.</p>
          </div>
          <div className="footer-links">
            <div className="footer-col">
              <h4>Product</h4>
              <Link to="/about">About</Link>
              <Link to="/support">Support</Link>
            </div>
            <div className="footer-col">
              <h4>Legal</h4>
              <Link to="/privacy">Privacy Policy</Link>
              <Link to="/terms">Terms of Service</Link>
            </div>
          </div>
        </div>
        <div className="footer-bottom">
          <p>&copy; {new Date().getFullYear()} Friendly. All rights reserved.</p>
        </div>
      </footer>
    </div>
  )
}

export default Layout
