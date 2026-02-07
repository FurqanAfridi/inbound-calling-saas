import React, { useState, useEffect } from 'react';
import { Activity, Monitor, MapPin, Clock, LogOut, AlertCircle, CheckCircle, XCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Alert, AlertDescription } from './ui/alert';
import { Badge } from './ui/badge';

interface LoginActivity {
  id: string;
  session_id: string | null;
  ip_address: string | null;
  user_agent: string | null;
  device_type: string | null;
  device_name: string | null;
  browser_name: string | null;
  os_name: string | null;
  location_country: string | null;
  location_city: string | null;
  login_method: string;
  success: boolean;
  failure_reason: string | null;
  login_at: string;
  logout_at: string | null;
  expires_at: string | null;
  is_active: boolean;
}

const LoginActivity: React.FC = () => {
  const { user, session } = useAuth();
  const [activities, setActivities] = useState<LoginActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [revokingSession, setRevokingSession] = useState<string | null>(null);

  useEffect(() => {
    if (user) {
      loadLoginActivity();
    }
  }, [user]);

  const loadLoginActivity = async () => {
    if (!user) return;

    setLoading(true);
    setError(null);

    try {
      const { data, error: fetchError } = await supabase
        .from('login_activity')
        .select('*')
        .eq('user_id', user.id)
        .order('login_at', { ascending: false })
        .limit(50);

      if (fetchError) {
        throw fetchError;
      }

      setActivities(data || []);
    } catch (err: any) {
      console.error('Error loading login activity:', err);
      setError(err.message || 'Failed to load login activity');
    } finally {
      setLoading(false);
    }
  };

  const revokeSession = async (activityId: string, sessionId: string | null) => {
    if (!user) return;

    if (!window.confirm('Are you sure you want to revoke this session? The user will be logged out from that device.')) {
      return;
    }

    setRevokingSession(activityId);
    setError(null);

    try {
      // Mark session as inactive
      const { error: updateError } = await supabase
        .from('login_activity')
        .update({
          is_active: false,
          logout_at: new Date().toISOString(),
        })
        .eq('id', activityId);

      if (updateError) {
        throw updateError;
      }

      // If this is the current session, sign out
      if (sessionId && session?.access_token) {
        // In a real implementation, you'd call a backend endpoint to revoke the session
        // For now, we'll just mark it as inactive in the database
        await supabase.auth.signOut();
      }

      // Log security event
      await supabase.rpc('log_security_event', {
        p_user_id: user.id,
        p_event_type: 'session_revoked',
        p_severity: 'medium',
        p_details: { session_id: sessionId, activity_id: activityId },
      });

      // Create notification
      await supabase.rpc('create_notification', {
        p_user_id: user.id,
        p_type: 'security_alert',
        p_title: 'Session Revoked',
        p_message: 'A login session has been revoked from your account.',
      });

      await loadLoginActivity();
    } catch (err: any) {
      setError(err.message || 'Failed to revoke session');
    } finally {
      setRevokingSession(null);
    }
  };

  const revokeAllOtherSessions = async () => {
    if (!user || !session) return;

    if (!window.confirm('Are you sure you want to revoke all other sessions? You will remain logged in on this device.')) {
      return;
    }

    setError(null);

    try {
      const currentSessionId = session.access_token;

      // Get all active sessions except current
      const { data: otherSessions, error: fetchError } = await supabase
        .from('login_activity')
        .select('id, session_id')
        .eq('user_id', user.id)
        .eq('is_active', true);

      if (fetchError) {
        throw fetchError;
      }

      // Revoke all other sessions
      const sessionIds = otherSessions
        ?.filter((s: { session_id: string | null; id: string }) => s.session_id !== currentSessionId)
        .map((s: { id: string }) => s.id) || [];

      if (sessionIds.length > 0) {
        const { error: updateError } = await supabase
          .from('login_activity')
          .update({
            is_active: false,
            logout_at: new Date().toISOString(),
          })
          .in('id', sessionIds);

        if (updateError) {
          throw updateError;
        }

        // Log security event
        await supabase.rpc('log_security_event', {
          p_user_id: user.id,
          p_event_type: 'session_revoked',
          p_severity: 'high',
          p_details: { revoked_count: sessionIds.length },
        });

        // Create notification
        await supabase.rpc('create_notification', {
          p_user_id: user.id,
          p_type: 'security_alert',
          p_title: 'All Other Sessions Revoked',
          p_message: `All other login sessions (${sessionIds.length}) have been revoked from your account.`,
        });
      }

      await loadLoginActivity();
    } catch (err: any) {
      setError(err.message || 'Failed to revoke sessions');
    }
  };

  const formatDate = (dateString: string | null): string => {
    if (!dateString) return 'Never';
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  const formatRelativeTime = (dateString: string | null): string => {
    if (!dateString) return 'Never';
    const date = new Date(dateString);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  const getDeviceInfo = (activity: LoginActivity): string => {
    const parts: string[] = [];
    if (activity.device_type) parts.push(activity.device_type);
    if (activity.os_name) parts.push(activity.os_name);
    if (activity.browser_name) parts.push(activity.browser_name);
    return parts.length > 0 ? parts.join(' • ') : 'Unknown Device';
  };

  const activeSessions = activities.filter(a => a.is_active);
  const currentSessionId = session?.access_token;

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {error && (
        <Alert variant="destructive" onClose={() => setError(null)}>
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-foreground flex items-center gap-2">
                <Activity className="w-5 h-5" />
                Login Activity & Sessions
              </CardTitle>
              <CardDescription className="text-muted-foreground">
                Monitor and manage your account's login sessions
              </CardDescription>
            </div>
            {activeSessions.length > 1 && (
              <Button
                variant="outline"
                onClick={revokeAllOtherSessions}
                className="text-destructive hover:text-destructive"
              >
                <LogOut className="w-4 h-4 mr-2" />
                Revoke All Other Sessions
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          <div className="mb-6">
            <div className="flex items-center gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Active Sessions: </span>
                <span className="font-semibold text-foreground">{activeSessions.length}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Total Logins: </span>
                <span className="font-semibold text-foreground">{activities.length}</span>
              </div>
            </div>
          </div>

          <div className="space-y-4">
            {activities.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <Activity className="w-12 h-12 mx-auto mb-4 opacity-50" />
                <p>No login activity found</p>
              </div>
            ) : (
              activities.map((activity) => {
                const isCurrentSession = activity.session_id === currentSessionId;
                const isActive = activity.is_active;

                return (
                  <Card key={activity.id} className={isActive ? 'border-primary' : ''}>
                    <CardContent className="pt-6">
                      <div className="flex items-start justify-between">
                        <div className="flex-1 space-y-3">
                          <div className="flex items-center gap-3">
                            {isActive ? (
                              <Badge variant="default" className="bg-green-500">
                                <CheckCircle className="w-3 h-3 mr-1" />
                                Active
                              </Badge>
                            ) : (
                              <Badge variant="outline">
                                <XCircle className="w-3 h-3 mr-1" />
                                Ended
                              </Badge>
                            )}
                            {isCurrentSession && (
                              <Badge variant="default">
                                Current Session
                              </Badge>
                            )}
                            {!activity.success && (
                              <Badge variant="destructive">
                                <AlertCircle className="w-3 h-3 mr-1" />
                                Failed
                              </Badge>
                            )}
                          </div>

                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                            <div className="flex items-start gap-2">
                              <Monitor className="w-4 h-4 mt-0.5 text-muted-foreground" />
                              <div>
                                <p className="text-muted-foreground">Device</p>
                                <p className="text-foreground font-medium">
                                  {getDeviceInfo(activity)}
                                </p>
                                {activity.device_name && (
                                  <p className="text-xs text-muted-foreground">{activity.device_name}</p>
                                )}
                              </div>
                            </div>

                            <div className="flex items-start gap-2">
                              <MapPin className="w-4 h-4 mt-0.5 text-muted-foreground" />
                              <div>
                                <p className="text-muted-foreground">Location</p>
                                <p className="text-foreground font-medium">
                                  {activity.location_city && activity.location_country
                                    ? `${activity.location_city}, ${activity.location_country}`
                                    : activity.location_country || 'Unknown'}
                                </p>
                                {activity.ip_address && (
                                  <p className="text-xs text-muted-foreground font-mono">{activity.ip_address}</p>
                                )}
                              </div>
                            </div>

                            <div className="flex items-start gap-2">
                              <Clock className="w-4 h-4 mt-0.5 text-muted-foreground" />
                              <div>
                                <p className="text-muted-foreground">Login Time</p>
                                <p className="text-foreground font-medium">
                                  {formatRelativeTime(activity.login_at)}
                                </p>
                                <p className="text-xs text-muted-foreground">
                                  {formatDate(activity.login_at)}
                                </p>
                              </div>
                            </div>

                            {activity.logout_at && (
                              <div className="flex items-start gap-2">
                                <LogOut className="w-4 h-4 mt-0.5 text-muted-foreground" />
                                <div>
                                  <p className="text-muted-foreground">Logout Time</p>
                                  <p className="text-foreground font-medium">
                                    {formatRelativeTime(activity.logout_at)}
                                  </p>
                                  <p className="text-xs text-muted-foreground">
                                    {formatDate(activity.logout_at)}
                                  </p>
                                </div>
                              </div>
                            )}
                          </div>

                          {activity.failure_reason && (
                            <div className="p-3 bg-destructive/10 border border-destructive/20 rounded text-sm">
                              <p className="text-destructive font-medium">Failure Reason:</p>
                              <p className="text-destructive/80">{activity.failure_reason}</p>
                            </div>
                          )}

                          <div className="text-xs text-muted-foreground">
                            <p>Method: <span className="font-medium capitalize">{activity.login_method}</span></p>
                            {activity.user_agent && (
                              <p className="mt-1 truncate" title={activity.user_agent}>
                                User Agent: {activity.user_agent}
                              </p>
                            )}
                          </div>
                        </div>

                        {isActive && !isCurrentSession && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => revokeSession(activity.id, activity.session_id)}
                            disabled={revokingSession === activity.id}
                            className="ml-4 text-destructive hover:text-destructive"
                          >
                            {revokingSession === activity.id ? (
                              'Revoking...'
                            ) : (
                              <>
                                <LogOut className="w-4 h-4 mr-2" />
                                Revoke
                              </>
                            )}
                          </Button>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                );
              })
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default LoginActivity;
