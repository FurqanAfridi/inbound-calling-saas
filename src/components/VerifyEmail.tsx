import React, { useState, useRef, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Mail, ArrowLeft } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Alert, AlertDescription } from './ui/alert';
import characterImage from '../assest/verification.png';

const VerifyEmail: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [otp, setOtp] = useState<string[]>(['', '', '', '', '', '', '', '']); // 8 digits for Supabase OTP
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

    if (value && index < 7) { // 8 digits (0-7)
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

    if (otpCode.length !== 8) {
      setError('Please enter the complete 8-digit code');
      return;
    }

    setLoading(true);

    try {
      if (purpose === 'password_reset') {
        // For password reset, verify OTP using Supabase
        const { data, error: verifyError } = await supabase.auth.verifyOtp({
          email: email,
          token: otpCode,
          type: 'recovery', // Password reset type
        });

        if (verifyError || !data.user) {
          setError('Invalid or expired OTP');
          setLoading(false);
          return;
        }

        navigate('/set-new-password', { state: { email } });
      } else {
        // For email verification, use Supabase verifyOtp
        const { data, error: verifyError } = await supabase.auth.verifyOtp({
          email: email,
          token: otpCode,
          type: 'signup', // Email verification type
        });

        if (verifyError) {
          setError(verifyError.message || 'Invalid or expired OTP');
          setLoading(false);
          return;
        }

        if (!data.user) {
          setError('User not found. Please sign up again.');
          setLoading(false);
          return;
        }

        // Update user profile to mark email as verified
        await supabase
          .from('user_profiles')
          .update({ email_verified: true })
          .eq('id', data.user.id);

        // Create notification
        await supabase.rpc('create_notification', {
          p_user_id: data.user.id,
          p_type: 'email_verification',
          p_title: 'Email Verified',
          p_message: 'Your email has been successfully verified.',
        });

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

      if (purpose === 'password_reset') {
        // Resend password reset OTP via Supabase
        const { error: resendError } = await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: `${window.location.origin}/verify-email?purpose=password_reset`,
        });

        if (resendError) {
          setError(resendError.message || 'Failed to resend OTP');
        } else {
          setError('OTP resent! Please check your email.');
        }
      } else {
        // Resend email verification OTP via Supabase
        const { error: resendError } = await supabase.auth.resend({
          type: 'signup',
          email: email,
        });

        if (resendError) {
          setError(resendError.message || 'Failed to resend OTP');
        } else {
          setError('OTP resent! Please check your email.');
        }
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
                Please enter the 8-digit code we just sent to {email || 'your email'}.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div className="flex justify-center gap-3" onPaste={handlePaste}>
                  {otp.map((digit, index) => (
                    <Input
                      key={index}
                      ref={(el) => { inputRefs.current[index] = el; }}
                      type="text"
                      inputMode="numeric"
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
