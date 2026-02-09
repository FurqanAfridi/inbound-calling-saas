import React, { useState, useRef, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Mail, ArrowLeft } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { emailService } from '../services/emailService';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Alert, AlertDescription } from './ui/alert';
import characterImage from '../assest/verification.png';

const VerifyEmail: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [otp, setOtp] = useState<string[]>(['', '', '', '', '', '']);
  const [email, setEmail] = useState<string>('');
  const [purpose, setPurpose] = useState<string>('email_verification');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    if (location.state) {
      setEmail(location.state.email || '');
      setPurpose(location.state.purpose || 'email_verification');
    }
  }, [location]);

  const handleChange = (index: number, value: string) => {
    if (value && !/^\d$/.test(value)) return;
    if (value.length > 1) return;
    
    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handleVerify = async () => {
    setError('');
    const otpCode = otp.join('');

    if (otpCode.length !== 6) {
      setError('Please enter the complete 6-digit code');
      return;
    }

    setLoading(true);

    try {
      if (purpose === 'password_reset') {
        const { data: tokens, error: tokenError } = await supabase
          .from('email_verification_tokens')
          .select('*')
          .eq('email', email)
          .eq('purpose', 'password_reset')
          .eq('token', otpCode)
          .is('used_at', null)
          .gt('expires_at', new Date().toISOString())
          .order('created_at', { ascending: false })
          .limit(1)
          .single();

        if (tokenError || !tokens) {
          setError('Invalid or expired OTP');
          setLoading(false);
          return;
        }

        await supabase
          .from('email_verification_tokens')
          .update({ used_at: new Date().toISOString() })
          .eq('id', tokens.id);

        navigate('/set-new-password', { state: { email, tokenId: tokens.id } });
      } else {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
          setError('User not found. Please sign up again.');
          setLoading(false);
          return;
        }

        const { data: tokens, error: tokenError } = await supabase
          .from('email_verification_tokens')
          .select('*')
          .eq('user_id', user.id)
          .eq('purpose', 'email_verification')
          .eq('token', otpCode)
          .is('used_at', null)
          .gt('expires_at', new Date().toISOString())
          .order('created_at', { ascending: false })
          .limit(1)
          .single();

        if (tokenError || !tokens) {
          setError('Invalid or expired OTP');
          setLoading(false);
          return;
        }

        await supabase
          .from('email_verification_tokens')
          .update({ used_at: new Date().toISOString() })
          .eq('id', tokens.id);

        // Update user profile to mark email as verified
        await supabase
          .from('user_profiles')
          .update({ email_verified: true })
          .eq('id', user.id);

        // Manually confirm email in Supabase Auth
        // Note: Supabase doesn't provide a direct client-side method to confirm email
        // The email will be confirmed when user signs in, or you can use admin API
        // For now, we'll mark it in our database and Supabase will auto-confirm on first login
        // OR you can create a backend endpoint that uses service_role key to confirm email
        
        // Create notification
        await supabase.rpc('create_notification', {
          p_user_id: user.id,
          p_type: 'email_verification',
          p_title: 'Email Verified',
          p_message: 'Your email has been successfully verified.',
        });

        // Refresh session data to ensure user is authenticated
        // getSession() will automatically refresh the session if needed
        await supabase.auth.getSession();

        navigate('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setError('');
    setLoading(true);

    try {
      if (!email) {
        setError('Email address is required');
        setLoading(false);
        return;
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + 10);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user && purpose === 'email_verification') {
        setError('User not found. Please sign up again.');
        setLoading(false);
        return;
      }

      if (user) {
        await supabase
          .from('email_verification_tokens')
          .insert({
            user_id: user.id,
            email: email,
            token: otp,
            token_hash: otp,
            purpose: purpose || 'email_verification',
            expires_at: expiresAt.toISOString(),
          });
      }

      const emailResult = await emailService.sendOTPEmail(
        email,
        otp,
        (purpose as 'email_verification' | 'password_reset') || 'email_verification'
      );

      if (emailResult.success) {
        setError('OTP resent! Please check your email.');
      } else {
        setError(emailResult.error || 'Failed to resend OTP');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to resend OTP');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-8">
      <div className="w-full max-w-6xl flex items-center gap-12">
        {/* Left Side - Image */}
        <div className="hidden lg:flex lg:w-1/2 justify-center items-center">
          <img src={characterImage} alt="Character" className="max-w-md w-full h-auto" />
        </div>

        {/* Right Side - Form */}
        <div className="w-full lg:w-1/2 flex justify-center">
          <Card className="w-full max-w-md">
            <CardHeader className="text-center">
              <CardTitle className="text-3xl font-bold text-foreground">Verify Your Email</CardTitle>
              <CardDescription className="text-muted-foreground">
                Please enter the code we just sent to email.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div className="flex justify-center gap-3">
                  {otp.map((digit, index) => (
                    <Input
                      key={index}
                      ref={(el) => { inputRefs.current[index] = el; }}
                      type="text"
                      maxLength={1}
                      value={digit}
                      onChange={(e) => handleChange(index, e.target.value)}
                      onKeyDown={(e) => handleKeyDown(index, e)}
                      placeholder="-"
                      className="w-14 h-14 text-center text-2xl font-bold bg-background text-foreground border-border"
                    />
                  ))}
                </div>

                <div className="text-center text-sm text-muted-foreground">
                  Didn't receive OTP?{' '}
                  <button
                    type="button"
                    onClick={handleResend}
                    className="text-primary hover:underline font-medium"
                  >
                    Resend Code
                  </button>
                </div>

                {error && (
                  <Alert variant={error.includes('resent') ? 'success' : 'destructive'}>
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                <Button
                  onClick={handleVerify}
                  className="w-full bg-primary hover:bg-primary/90 text-primary-foreground"
                  disabled={loading}
                >
                  {loading ? 'Verifying...' : 'Done'}
                </Button>

                <div className="text-center text-sm text-muted-foreground">
                  Back To <Link to="/" className="text-primary hover:underline font-medium">Sign in</Link>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default VerifyEmail;
