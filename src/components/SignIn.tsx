import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Mail, Lock } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import { emailService } from '../services/emailService';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import characterImage from '../assest/signin.png';

import TwoFactorLogin from './TwoFactorLogin';

const SignIn: React.FC = () => {
  const navigate = useNavigate();
  const { signIn } = useAuth();
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [agreeTerms, setAgreeTerms] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const [show2FA, setShow2FA] = useState<boolean>(false);
  const [pendingUserId, setPendingUserId] = useState<string | null>(null);
  const [pendingUserEmail, setPendingUserEmail] = useState<string>('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('Please enter email and password');
      return;
    }

    if (!agreeTerms) {
      setError('Please agree to the Terms & Privacy');
      return;
    }

    setLoading(true);

    try {
      const { error: signInError } = await signIn(email, password);

      if (signInError) {
        setError(signInError.message || 'Invalid email or password');
        setLoading(false);
        return;
      }

      // Check if user has 2FA enabled
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        // Check 2FA status
        const { data: twoFactorData } = await supabase
          .from('user_2fa')
          .select('enabled, verified')
          .eq('user_id', user.id)
          .single();

        // If 2FA is enabled and verified, show 2FA verification screen
        if (twoFactorData?.enabled && twoFactorData?.verified) {
          setPendingUserId(user.id);
          setPendingUserEmail(user.email || '');
          setShow2FA(true);
          setLoading(false);
          return;
        }

        // If no 2FA, proceed with normal login flow
        await completeLogin(user, false);
      } else {
        // Navigate to dashboard if no user (shouldn't happen)
        navigate('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
      setLoading(false);
    }
  };

  const completeLogin = async (user: any, used2FA: boolean = false) => {
    try {
      // Get user IP and device info
      const ipResponse = await fetch('https://api.ipify.org?format=json').catch(() => null);
      const ipData = ipResponse ? await ipResponse.json() : { ip: null };
      const ipAddress = ipData.ip;

      // Get device info
      const userAgent = navigator.userAgent;
      const deviceType = /Mobile|Android|iPhone|iPad/.test(userAgent) ? 'mobile' : 'desktop';
      const browserName = userAgent.match(/(Chrome|Firefox|Safari|Edge|Opera)\/[\d.]+/)?.[1] || 'Unknown';
      const osName = userAgent.match(/(Windows|Mac|Linux|Android|iOS)/)?.[1] || 'Unknown';

      await supabase.rpc('log_login_activity', {
        p_user_id: user.id,
        p_session_id: null,
        p_ip_address: ipAddress,
        p_user_agent: userAgent,
        p_login_method: used2FA ? '2fa' : 'email'
      });

      // Update last login
      await supabase
        .from('user_profiles')
        .update({ last_login_at: new Date().toISOString(), last_active_at: new Date().toISOString() })
        .eq('id', user.id);

      // Send login alert email (check if this is a new device/location)
      try {
        const { data: previousLogins } = await supabase
          .from('login_activity')
          .select('ip_address, device_type, browser_name')
          .eq('user_id', user.id)
          .order('login_at', { ascending: false })
          .limit(5);

        const isNewDevice = !previousLogins?.some((login: { device_type: string | null; browser_name: string | null }) => 
          login.device_type === deviceType && 
          login.browser_name === browserName
        );

        if (isNewDevice && user.email) {
          await emailService.sendNewDeviceLoginEmail(user.email, {
            ip: ipAddress || undefined,
            device: `${deviceType} • ${osName} • ${browserName}`,
            location: 'Unknown', // In production, use a geolocation service
          });
        } else if (user.email) {
          await emailService.sendLoginAlertEmail(user.email, {
            ip: ipAddress || undefined,
            device: `${deviceType} • ${osName} • ${browserName}`,
            location: 'Unknown',
            time: new Date().toLocaleString(),
          });
        }
      } catch (emailError) {
        console.error('Error sending login alert email:', emailError);
        // Don't block login if email fails
      }

      // Navigate to dashboard
      navigate('/dashboard');
    } catch (err: any) {
      console.error('Error completing login:', err);
      setError('Failed to complete login. Please try again.');
    }
  };

  const handle2FASuccess = async () => {
    if (!pendingUserId) return;

    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      await completeLogin(user, true);
    }
  };

  const handle2FACancel = () => {
    // Sign out the user since they haven't completed 2FA
    supabase.auth.signOut();
    setShow2FA(false);
    setPendingUserId(null);
    setPendingUserEmail('');
    setError('Login cancelled. Please sign in again.');
  };

  // Show 2FA verification screen if needed
  if (show2FA && pendingUserId) {
    return (
      <TwoFactorLogin
        userId={pendingUserId}
        userEmail={pendingUserEmail}
        onSuccess={handle2FASuccess}
        onCancel={handle2FACancel}
      />
    );
  }

  return (
    <div className="min-h-screen bg-background flex">
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary to-secondary p-12 relative overflow-hidden">
        <div className="relative z-10 flex flex-col justify-between h-full">
          <div>
            <h1 className="text-5xl font-bold text-white mb-4 leading-tight">
              Sign in to your<br />
              creative HQ
            </h1>
            <div className="w-64 h-1 bg-white/90 rounded mb-8"></div>
            <p className="text-white/90 text-lg leading-relaxed">
              Unlock the power of DNAI-driven<br />
              social media intelligence.<br />
              Create, analyze, and dominate<br />
              your social presence with<br />
              cutting-edge tools.
            </p>
          </div>
          <div className="flex justify-center items-end">
            <img src={characterImage} alt="Character" className="max-w-md w-full h-auto" />
          </div>
        </div>
      </div>

      {/* Right Side - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 lg:p-12">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <CardTitle className="text-3xl font-bold text-foreground">Welcome back!</CardTitle>
            <CardDescription className="text-muted-foreground">Good to see you again.</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="email" className="text-foreground">Email Address</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="123@gmail.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-10 bg-background text-foreground border-border"
                  />
                </div>
              </div>

              <div className="flex justify-end">
                <Link to="/reset-password" className="text-sm text-primary hover:underline">
                  Forget Password?
                </Link>
              </div>

              <div className="space-y-2">
                <Label htmlFor="password" className="text-foreground">Password</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="Enter Your Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="pl-10 pr-10 bg-background text-foreground border-border"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="terms"
                  checked={agreeTerms}
                  onChange={(e) => setAgreeTerms(e.target.checked)}
                  className="w-4 h-4 rounded border-border text-primary focus:ring-primary"
                />
                <Label htmlFor="terms" className="text-sm text-muted-foreground cursor-pointer">
                  I agree to the Terms & Privacy
                </Label>
              </div>

              {error && (
                <div className="bg-destructive/10 border border-destructive/20 text-destructive px-4 py-3 rounded-lg text-sm">
                  {error}
                </div>
              )}

              <Button
                type="submit"
                className="w-full bg-primary hover:bg-primary/90 text-primary-foreground"
                disabled={loading}
              >
                {loading ? 'Signing in...' : 'Sign in'}
              </Button>

              <div className="text-center text-sm text-muted-foreground">
                Don't have an account? <Link to="/signup" className="text-primary hover:underline font-medium">Sign up</Link>
              </div>

              <div className="relative">
                <div className="absolute inset-0 flex items-center">
                  <span className="w-full border-t border-border"></span>
                </div>
                <div className="relative flex justify-center text-xs uppercase">
                  <span className="bg-card px-2 text-muted-foreground">or</span>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <Button type="button" variant="outline" className="flex items-center justify-center gap-2">
                  <svg width="20" height="20" viewBox="0 0 24 24">
                    <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  </svg>
                </Button>
                <Button type="button" variant="outline" className="flex items-center justify-center gap-2">
                  <svg width="20" height="20" viewBox="0 0 24 24">
                    <path fill="#000000" d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
                  </svg>
                </Button>
                <Button type="button" variant="outline" className="flex items-center justify-center gap-2">
                  <svg width="20" height="20" viewBox="0 0 24 24">
                    <path fill="#1877F2" d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                  </svg>
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SignIn;
