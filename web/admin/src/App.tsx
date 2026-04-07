import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './lib/supabase'
import { adminFetch } from './lib/api'
import './App.css'

type PortalMe = {
  user_id: string
  role: string
  is_admin: boolean
}

type AdminMetrics = {
  users: number
  friendships: number
  check_ins: number
  interactions: number
  ambient_signals: number
  device_state: number
}

type AdminProfile = {
  id: string
  display_name: string
  avatar_url?: string | null
  phone_number?: string | null
  email?: string | null
  created_at: string
}

type AdminFriendship = {
  id: string
  user_id: string
  friend_id: string
  status: string
  created_at: string
  updated_at: string
}

type AdminUser = {
  user_id: string
  role: string
  created_at: string
  profile?: AdminProfile | null
}

type TesterReport = {
  id: string
  user_id: string
  type: string
  title: string
  description: string
  severity: string
  screenshots: string[]
  device?: string | null
  app_version?: string | null
  contact?: string | null
  status: string
  github_issue_url?: string | null
  github_issue_number?: number | null
  created_at: string
  updated_at: string
}

function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [authLoading, setAuthLoading] = useState(true)
  const [portalStatus, setPortalStatus] = useState<PortalMe | null>(null)
  const [portalLoading, setPortalLoading] = useState(false)
  const [portalError, setPortalError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<string>('Overview')
  const [metrics, setMetrics] = useState<AdminMetrics | null>(null)
  const [users, setUsers] = useState<AdminProfile[]>([])
  const [friendships, setFriendships] = useState<AdminFriendship[]>([])
  const [admins, setAdmins] = useState<AdminUser[]>([])
  const [reports, setReports] = useState<TesterReport[]>([])
  const [userQuery, setUserQuery] = useState('')
  const [friendshipQuery, setFriendshipQuery] = useState('')
  const [newAdminId, setNewAdminId] = useState('')
  const [newAdminRole, setNewAdminRole] = useState('admin')
  const [actionMessage, setActionMessage] = useState<string | null>(null)
  const [reportType, setReportType] = useState('bug')
  const [reportTitle, setReportTitle] = useState('')
  const [reportDescription, setReportDescription] = useState('')
  const [reportSeverity, setReportSeverity] = useState('medium')
  const [reportScreenshots, setReportScreenshots] = useState('')
  const [reportDevice, setReportDevice] = useState('')
  const [reportAppVersion, setReportAppVersion] = useState('')
  const [reportContact, setReportContact] = useState('')
  const [reportStatusFilter, setReportStatusFilter] = useState('')
  const [reportTypeFilter, setReportTypeFilter] = useState('')
  const [selectedReportId, setSelectedReportId] = useState<string | null>(null)

  const accessToken = session?.access_token ?? ''
  const hasEnv = Boolean(
    import.meta.env.VITE_SUPABASE_URL &&
    import.meta.env.VITE_SUPABASE_ANON_KEY &&
    import.meta.env.VITE_ADMIN_API_URL,
  )

  useEffect(() => {
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session ?? null)
      setAuthLoading(false)
    })
    const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession)
    })
    return () => {
      mounted = false
      data.subscription.unsubscribe()
    }
  }, [])

  useEffect(() => {
    if (!session) {
      setPortalStatus(null)
      setPortalError(null)
      return
    }
    const verifyPortal = async () => {
      setPortalLoading(true)
      setPortalError(null)
      try {
        const me = await adminFetch<PortalMe>('/tester/me', accessToken)
        setPortalStatus(me)
      } catch (error) {
        setPortalStatus(null)
        setPortalError(error instanceof Error ? error.message : 'Portal access denied')
      } finally {
        setPortalLoading(false)
      }
    }
    verifyPortal()
  }, [accessToken, session])

  const loadMetrics = async () => {
    const data = await adminFetch<AdminMetrics>('/admin/metrics', accessToken)
    setMetrics(data)
  }

  const loadUsers = async () => {
    const query = userQuery.trim()
    const path = query ? `/admin/users?q=${encodeURIComponent(query)}` : '/admin/users'
    const data = await adminFetch<AdminProfile[]>(path, accessToken)
    setUsers(data)
  }

  const loadFriendships = async () => {
    const query = friendshipQuery.trim()
    const path = query ? `/admin/friendships?user_id=${encodeURIComponent(query)}` : '/admin/friendships'
    const data = await adminFetch<AdminFriendship[]>(path, accessToken)
    setFriendships(data)
  }

  const loadAdmins = async () => {
    const data = await adminFetch<AdminUser[]>('/admin/admins', accessToken)
    setAdmins(data)
  }

  useEffect(() => {
    if (!portalStatus?.is_admin) return
    Promise.all([loadMetrics(), loadUsers(), loadFriendships(), loadAdmins(), loadReports()]).catch((error) => {
      setPortalError(error instanceof Error ? error.message : 'Failed to load admin data')
    })
  }, [portalStatus])

  useEffect(() => {
    if (!portalStatus) return
    setActiveTab(portalStatus.is_admin ? 'Overview' : 'Feedback')
    loadReports().catch((error) => {
      setPortalError(error instanceof Error ? error.message : 'Failed to load reports')
    })
  }, [portalStatus])

  useEffect(() => {
    if (activeTab !== 'Feedback') return
    loadReports().catch(() => undefined)
  }, [activeTab])

  const loadReports = async () => {
    const params = new URLSearchParams()
    if (reportStatusFilter) params.set('status', reportStatusFilter)
    if (reportTypeFilter) params.set('report_type', reportTypeFilter)
    const path = params.toString() ? `/tester/reports?${params.toString()}` : '/tester/reports'
    const data = await adminFetch<TesterReport[]>(path, accessToken)
    setReports(data)
  }

  const handleSubmitReport = async () => {
    setActionMessage(null)
    if (!reportTitle.trim() || !reportDescription.trim()) {
      setActionMessage('Title and description are required.')
      return
    }
    try {
      const screenshots = reportScreenshots
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean)
      await adminFetch('/tester/reports', accessToken, {
        method: 'POST',
        body: JSON.stringify({
          type: reportType,
          title: reportTitle.trim(),
          description: reportDescription.trim(),
          severity: reportSeverity,
          screenshots,
          device: reportDevice.trim() || null,
          app_version: reportAppVersion.trim() || null,
          contact: reportContact.trim() || null,
        }),
      })
      setReportTitle('')
      setReportDescription('')
      setReportScreenshots('')
      setReportDevice('')
      setReportAppVersion('')
      setReportContact('')
      setActionMessage('Feedback submitted. Thank you!')
      await loadReports()
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : 'Failed to submit feedback.')
    }
  }

  const handleStatusUpdate = async (reportId: string, status: string) => {
    setActionMessage(null)
    try {
      await adminFetch(`/tester/reports/${reportId}/status`, accessToken, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      })
      await loadReports()
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : 'Failed to update status.')
    }
  }

  const handleCreateGitHubIssue = async (reportId: string, target: string) => {
    setActionMessage(null)
    try {
      const result = await adminFetch<{ url: string; number: number }>(
        `/tester/reports/${reportId}/github-issue?target=${encodeURIComponent(target)}`,
        accessToken,
        { method: 'POST' },
      )
      setActionMessage(`GitHub issue #${result.number} created.`)
      await loadReports()
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : 'Failed to create GitHub issue.')
    }
  }

  const handleAddAdmin = async () => {
    if (!newAdminId.trim()) return
    setActionMessage(null)
    try {
      await adminFetch('/admin/admins', accessToken, {
        method: 'POST',
        body: JSON.stringify({ user_id: newAdminId.trim(), role: newAdminRole }),
      })
      setNewAdminId('')
      setActionMessage('Admin access granted.')
      await loadAdmins()
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : 'Failed to add admin.')
    }
  }

  const handleRemoveAdmin = async (userId: string) => {
    setActionMessage(null)
    try {
      await adminFetch(`/admin/admins/${userId}`, accessToken, { method: 'DELETE' })
      setActionMessage('Admin access removed.')
      await loadAdmins()
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : 'Failed to remove admin.')
    }
  }

  const formatDate = (value: string) => new Date(value).toLocaleString()

  const overviewStats = useMemo(() => {
    if (!metrics) return []
    return [
      { label: 'Users', value: metrics.users },
      { label: 'Connections', value: metrics.friendships },
      { label: 'Check-ins', value: metrics.check_ins },
      { label: 'Interactions', value: metrics.interactions },
      { label: 'Ambient signals', value: metrics.ambient_signals },
      { label: 'Devices', value: metrics.device_state },
    ]
  }, [metrics])

  if (!hasEnv) {
    return (
      <div className="page">
        <div className="glass warning">
          <h1>Missing Supabase configuration</h1>
          <p>
            Set <code>VITE_SUPABASE_URL</code>, <code>VITE_SUPABASE_ANON_KEY</code>, and
            <code>VITE_ADMIN_API_URL</code> to continue.
          </p>
        </div>
      </div>
    )
  }

  if (authLoading) {
    return (
      <div className="page">
        <div className="glass">
          <h1>Loading Friendly Admin</h1>
          <p>Warming up secure session...</p>
        </div>
      </div>
    )
  }

  if (!session) {
    return <Login />
  }

  if (portalLoading) {
    return (
      <div className="page">
        <div className="glass">
          <h1>Verifying portal access</h1>
          <p>Confirming your portal permissions.</p>
        </div>
      </div>
    )
  }

  if (portalError || !portalStatus) {
    return (
      <div className="page">
        <div className="glass warning">
          <h1>Portal access required</h1>
          <p>{portalError ?? 'This account is not authorized for the portal.'}</p>
          <button className="secondary" onClick={() => supabase.auth.signOut()}>Sign out</button>
        </div>
      </div>
    )
  }

  const tabs = portalStatus.is_admin
    ? ['Overview', 'Users', 'Connections', 'Admins', 'Feedback']
    : ['Feedback']

  return (
    <div className="page">
      <div className="halo" />
      <header className="topbar">
        <div>
          <p className="eyebrow">Friendly Portal</p>
          <h1>{portalStatus.is_admin ? 'Control Room' : 'Feedback Hub'}</h1>
        </div>
        <div className="topbar-actions">
          <div className="badge">{portalStatus.role.toUpperCase()}</div>
          <button className="secondary" onClick={() => supabase.auth.signOut()}>Sign out</button>
        </div>
      </header>

      <div className="layout">
        <aside className="sidebar">
          {tabs.map((tab) => (
            <button
              key={tab}
              className={tab === activeTab ? 'tab active' : 'tab'}
              onClick={() => setActiveTab(tab)}
            >
              {tab}
            </button>
          ))}
          <div className="sidebar-foot">
            <p>Signed in as</p>
            <span>{session.user.email ?? session.user.id}</span>
          </div>
        </aside>

        <main className="content">
          {portalStatus.is_admin && activeTab === 'Overview' && (
            <section className="panel">
              <div className="panel-header">
                <div>
                  <h2>System overview</h2>
                  <p>Live totals from core tables.</p>
                </div>
                <button onClick={loadMetrics}>Refresh</button>
              </div>
              <div className="stat-grid">
                {overviewStats.map((stat) => (
                  <div key={stat.label} className="stat-card">
                    <span>{stat.label}</span>
                    <strong>{stat.value.toLocaleString()}</strong>
                  </div>
                ))}
              </div>
            </section>
          )}

          {portalStatus.is_admin && activeTab === 'Users' && (
            <section className="panel">
              <div className="panel-header">
                <div>
                  <h2>Users</h2>
                  <p>Profiles registered in Friendly.</p>
                </div>
                <div className="controls">
                  <input
                    placeholder="Search display name"
                    value={userQuery}
                    onChange={(event) => setUserQuery(event.target.value)}
                  />
                  <button onClick={loadUsers}>Search</button>
                </div>
              </div>
              <div className="table">
                <div className="table-row header">
                  <span>ID</span>
                  <span>Name</span>
                  <span>Contact</span>
                  <span>Created</span>
                </div>
                {users.map((user) => (
                  <div className="table-row" key={user.id}>
                    <span className="mono">{user.id}</span>
                    <span>{user.display_name || '—'}</span>
                    <span>{user.email || user.phone_number || '—'}</span>
                    <span>{formatDate(user.created_at)}</span>
                  </div>
                ))}
              </div>
            </section>
          )}

          {portalStatus.is_admin && activeTab === 'Connections' && (
            <section className="panel">
              <div className="panel-header">
                <div>
                  <h2>Connections</h2>
                  <p>Friendship links and their state.</p>
                </div>
                <div className="controls">
                  <input
                    placeholder="Filter by user ID"
                    value={friendshipQuery}
                    onChange={(event) => setFriendshipQuery(event.target.value)}
                  />
                  <button onClick={loadFriendships}>Search</button>
                </div>
              </div>
              <div className="table">
                <div className="table-row header five">
                  <span>ID</span>
                  <span>User</span>
                  <span>Friend</span>
                  <span>Status</span>
                  <span>Updated</span>
                </div>
                {friendships.map((friendship) => (
                  <div className="table-row five" key={friendship.id}>
                    <span className="mono">{friendship.id}</span>
                    <span className="mono">{friendship.user_id}</span>
                    <span className="mono">{friendship.friend_id}</span>
                    <span className={`pill ${friendship.status}`}>{friendship.status}</span>
                    <span>{formatDate(friendship.updated_at)}</span>
                  </div>
                ))}
              </div>
            </section>
          )}

          {portalStatus.is_admin && activeTab === 'Admins' && (
            <section className="panel">
              <div className="panel-header">
                <div>
                  <h2>Admin access</h2>
                  <p>Manage who can access the portal.</p>
                </div>
                <button onClick={loadAdmins}>Refresh</button>
              </div>
              <div className="admin-form">
                <input
                  placeholder="User ID"
                  value={newAdminId}
                  onChange={(event) => setNewAdminId(event.target.value)}
                />
                <select value={newAdminRole} onChange={(event) => setNewAdminRole(event.target.value)}>
                  <option value="admin">Admin</option>
                  <option value="super_admin">Super admin</option>
                </select>
                <button onClick={handleAddAdmin}>Grant access</button>
              </div>
              {actionMessage && <p className="hint">{actionMessage}</p>}
              <div className="table">
                <div className="table-row header five">
                  <span>ID</span>
                  <span>Name</span>
                  <span>Role</span>
                  <span>Granted</span>
                  <span>Action</span>
                </div>
                {admins.map((adminUser) => (
                  <div className="table-row five" key={adminUser.user_id}>
                    <span className="mono">{adminUser.user_id}</span>
                    <span>{adminUser.profile?.display_name || '—'}</span>
                    <span>{adminUser.role}</span>
                    <span>{formatDate(adminUser.created_at)}</span>
                    <span>
                      <button className="ghost" onClick={() => handleRemoveAdmin(adminUser.user_id)}>Remove</button>
                    </span>
                  </div>
                ))}
              </div>
            </section>
          )}

          {activeTab === 'Feedback' && (
            <section className="panel">
              <div className="panel-header">
                <div>
                  <h2>Tester feedback</h2>
                  <p>Capture bugs, UI notes, and feature ideas from pilot users.</p>
                </div>
                <button onClick={loadReports}>Refresh</button>
              </div>

              <div className="feedback-form">
                <div className="field">
                  <label>Type</label>
                  <select value={reportType} onChange={(event) => setReportType(event.target.value)}>
                    <option value="bug">Bug</option>
                    <option value="ui">UI</option>
                    <option value="feature">Feature</option>
                  </select>
                </div>
                <div className="field">
                  <label>Severity</label>
                  <select value={reportSeverity} onChange={(event) => setReportSeverity(event.target.value)}>
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                    <option value="critical">Critical</option>
                  </select>
                </div>
                <div className="field wide">
                  <label>Title</label>
                  <input
                    placeholder="Short summary"
                    value={reportTitle}
                    onChange={(event) => setReportTitle(event.target.value)}
                  />
                </div>
                <div className="field wide">
                  <label>Description</label>
                  <textarea
                    placeholder="What happened or what you suggest"
                    value={reportDescription}
                    onChange={(event) => setReportDescription(event.target.value)}
                    rows={4}
                  />
                </div>
                <div className="field wide">
                  <label>Screenshots / links (comma separated)</label>
                  <input
                    placeholder="https://… , https://…"
                    value={reportScreenshots}
                    onChange={(event) => setReportScreenshots(event.target.value)}
                  />
                </div>
                <div className="field">
                  <label>Device</label>
                  <input
                    placeholder="iPhone 15, Pixel 8, etc."
                    value={reportDevice}
                    onChange={(event) => setReportDevice(event.target.value)}
                  />
                </div>
                <div className="field">
                  <label>App version</label>
                  <input
                    placeholder="1.0.3"
                    value={reportAppVersion}
                    onChange={(event) => setReportAppVersion(event.target.value)}
                  />
                </div>
                <div className="field wide">
                  <label>Contact</label>
                  <input
                    placeholder="Email or phone"
                    value={reportContact}
                    onChange={(event) => setReportContact(event.target.value)}
                  />
                </div>
                <div className="field wide">
                  <button onClick={handleSubmitReport}>Submit feedback</button>
                </div>
              </div>

              {actionMessage && <p className="hint">{actionMessage}</p>}

              <div className="filters">
                <select value={reportTypeFilter} onChange={(event) => setReportTypeFilter(event.target.value)}>
                  <option value="">All types</option>
                  <option value="bug">Bug</option>
                  <option value="ui">UI</option>
                  <option value="feature">Feature</option>
                </select>
                <select value={reportStatusFilter} onChange={(event) => setReportStatusFilter(event.target.value)}>
                  <option value="">All status</option>
                  <option value="new">New</option>
                  <option value="triage">Triage</option>
                  <option value="in_progress">In progress</option>
                  <option value="resolved">Resolved</option>
                  <option value="closed">Closed</option>
                </select>
                <button onClick={loadReports}>Apply</button>
              </div>

              <div className="table">
                <div className={`table-row header ${portalStatus.is_admin ? 'six' : 'five'}`}>
                  <span>Title</span>
                  <span>Type</span>
                  <span>Severity</span>
                  <span>Status</span>
                  <span>Created</span>
                  {portalStatus.is_admin && <span>Action</span>}
                </div>
                {reports.map((report) => (
                  <div key={report.id}>
                    <div
                      className={`table-row clickable ${portalStatus.is_admin ? 'six' : 'five'} ${selectedReportId === report.id ? 'selected' : ''}`}
                      onClick={() => setSelectedReportId(selectedReportId === report.id ? null : report.id)}
                    >
                      <span>{report.title}</span>
                      <span className="pill">{report.type}</span>
                      <span className={`pill ${report.severity}`}>{report.severity}</span>
                      <span className={`pill ${report.status}`}>{report.status}</span>
                      <span>{formatDate(report.created_at)}</span>
                      {portalStatus.is_admin && (
                        <span>
                          <select
                            value={report.status}
                            onClick={(event) => event.stopPropagation()}
                            onChange={(event) => handleStatusUpdate(report.id, event.target.value)}
                          >
                            <option value="new">New</option>
                            <option value="triage">Triage</option>
                            <option value="in_progress">In progress</option>
                            <option value="resolved">Resolved</option>
                            <option value="closed">Closed</option>
                          </select>
                        </span>
                      )}
                    </div>
                    {selectedReportId === report.id && (
                      <div className="report-detail">
                        <div className="report-detail-section">
                          <h3>Description</h3>
                          <p>{report.description}</p>
                        </div>
                        {report.screenshots.length > 0 && (
                          <div className="report-detail-section">
                            <h3>Screenshots / links</h3>
                            <ul>
                              {report.screenshots.map((url, i) => (
                                <li key={i}>
                                  <a href={url} target="_blank" rel="noopener noreferrer">{url}</a>
                                </li>
                              ))}
                            </ul>
                          </div>
                        )}
                        <div className="report-detail-meta">
                          {report.device && <div><strong>Device</strong><span>{report.device}</span></div>}
                          {report.app_version && <div><strong>App version</strong><span>{report.app_version}</span></div>}
                          {report.contact && <div><strong>Contact</strong><span>{report.contact}</span></div>}
                          <div><strong>Submitted</strong><span>{formatDate(report.created_at)}</span></div>
                          <div><strong>Updated</strong><span>{formatDate(report.updated_at)}</span></div>
                        </div>
                        {portalStatus.is_admin && (
                          <div className="report-detail-actions">
                            {report.github_issue_url ? (
                              <a
                                href={report.github_issue_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="github-issue-link"
                              >
                                GitHub Issue #{report.github_issue_number}
                              </a>
                            ) : (
                              <div className="github-issue-create">
                                <select className="repo-select" id={`repo-${report.id}`} defaultValue="api">
                                  <option value="api">API</option>
                                  <option value="mobile">Mobile</option>
                                  <option value="web">Web</option>
                                </select>
                                <button
                                  className="secondary"
                                  onClick={() => {
                                    const select = document.getElementById(`repo-${report.id}`) as HTMLSelectElement
                                    handleCreateGitHubIssue(report.id, select.value)
                                  }}
                                >
                                  Create GitHub Issue
                                </button>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </section>
          )}
        </main>
      </div>
    </div>
  )
}

function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError(null)
    setLoading(true)
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (signInError) {
      setError(signInError.message)
    }
    setLoading(false)
  }

  return (
    <div className="page">
      <div className="halo" />
      <div className="login">
        <div className="login-card glass">
          <p className="eyebrow">Friendly Portal</p>
          <h1>Secure sign-in</h1>
          <p className="subtle">
            Use your Supabase login to access the tester feedback portal.
          </p>
          <form onSubmit={handleSubmit}>
            <label>
              Email
              <input
                type="email"
                autoComplete="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
              />
            </label>
            <label>
              Password
              <input
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
              />
            </label>
            {error && <p className="hint error">{error}</p>}
            <button type="submit" disabled={loading}>
              {loading ? 'Signing in…' : 'Sign in'}
            </button>
          </form>
        </div>
        <div className="login-note">
          <h2>Access is role-gated</h2>
          <p>
            Accounts must exist in <code>admin_users</code> or <code>user_roles</code>.
          </p>
        </div>
      </div>
    </div>
  )
}

export default App
