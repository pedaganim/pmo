import { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState<string>('Loading...');

  useEffect(() => {
    fetch('/api/hello')
      .then(res => res.json())
      .then(data => setMessage(data.message))
      .catch(() => setMessage('Backend Unreachable (Check if running)'));
  }, []);

  return (
    <div className="app-container">
      <nav className="navbar">
        <div className="logo">PMO<span>.ai</span></div>
        <div className="nav-links">
          <a href="#features">Features</a>
          <a href="#about">About</a>
          <button className="btn-primary">Get Started</button>
        </div>
      </nav>

      <main className="hero-section">
        <div className="hero-content">
          <h1>Manage Projects with <span className="gradient-text">Precision.</span></h1>
          <p className="subtitle">
            The next-generation Kanban board for high-performance teams. 
            Whitelabelable, secure, and powered by Microsoft SSO.
          </p>
          <div className="hero-actions">
            <button className="btn-large">Launch Board</button>
            <button className="btn-secondary">View Demo</button>
          </div>
          <div className="backend-status">
            <span className="dot"></span>
            Status: {message}
          </div>
        </div>
        <div className="hero-visual">
          <div className="glass-card">
            <div className="card-header">
              <div className="dot red"></div>
              <div className="dot yellow"></div>
              <div className="dot green"></div>
            </div>
            <div className="card-body">
              <div className="skeleton-line wide"></div>
              <div className="skeleton-line medium"></div>
              <div className="skeleton-line short"></div>
              <div className="kanban-mini">
                <div className="column"></div>
                <div className="column"></div>
                <div className="column active"></div>
              </div>
            </div>
          </div>
        </div>
      </main>

      <footer className="footer">
        <p>&copy; 2026 PMO Inc. Built with Spring Boot & React.</p>
      </footer>
    </div>
  );
}

export default App;
