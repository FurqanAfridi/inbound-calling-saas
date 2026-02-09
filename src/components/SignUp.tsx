import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Mail, Lock, User, Phone } from 'lucide-react';
import { supabase } from '../lib/supabase';
import CountryCodeSelector from './CountryCodeSelector';
import { emailService } from '../services/emailService';
import { assignFreePackageToUser } from '../services/subscriptionService';
import { validatePassword } from '../utils/passwordValidation';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import characterImage from '../assest/signup.png';

interface FormData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  password: string;
  confirmPassword: string;
}

const SignUp: React.FC = () => {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState<boolean>(false);
  const [countryCode, setCountryCode] = useState<string>('+1');
  const [formData, setFormData] = useState<FormData>({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    password: '',
    confirmPassword: ''
  });
  const [agreeTerms, setAgreeTerms] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
    setError('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validation
    if (!formData.firstName || !formData.lastName || !formData.email || !formData.phone || !formData.password) {
      setError('Please fill in all required fields');
      return;
    }

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    // Validate password strength
    const passwordValidation = validatePassword(formData.password);
    if (!passwordValidation.isValid) {
      setError(passwordValidation.errors.join('. '));
      return;
    }

    if (!agreeTerms) {
      setError('Please agree to the Terms & Privacy');
      return;
    }

    setLoading(true);

    try {
      // Sign up with Supabase - This will automatically send OTP via Supabase
      const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          emailRedirectTo: null, // Disable automatic email confirmation link
          data: {
            first_name: formData.firstName,
            last_name: formData.lastName,
            phone: `${countryCode}${formData.phone}`,
            country_code: countryCode,
          },
        },
      });

      if (signUpError) {
        // Handle existing user error properly
        if (signUpError.message?.includes('already registered') || 
            signUpError.message?.includes('User already registered') ||
            signUpError.message?.includes('email address is already registered')) {
          setError('An account with this email already exists. Please sign in instead.');
        } else {
          setError(signUpError.message || 'Failed to create account');
        }
        setLoading(false);
        return;
      }

      if (signUpData.user) {
        // Ensure user ID exists
        if (!signUpData.user.id) {
          console.error('User ID is missing from signup data');
          setError('Failed to create user account. Please try again.');
          setLoading(false);
          return;
        }

        // Create user profile - ensure it's saved properly with all required fields
        // Format phone number correctly (ensure country code is included)
        const phoneNumber = formData.phone.startsWith(countryCode) 
          ? formData.phone 
          : `${countryCode}${formData.phone}`;
        
        const profileData = {
          id: signUpData.user.id,
          first_name: formData.firstName || null,
          last_name: formData.lastName || null,
          phone: phoneNumber || null,
          country_code: countryCode || '+1',
          email_verified: false,
          phone_verified: false,
          account_status: 'active', // Explicitly set account status
          kyc_status: 'pending', // Set default KYC status
          metadata: {}, // Initialize metadata as empty object
        };

        console.log('Creating user profile with data:', profileData);
        console.log('User ID:', signUpData.user.id);
        console.log('User Email:', signUpData.user.email);

        // Try insert first, if it fails due to conflict, use upsert
        const { error: insertError } = await supabase
          .from('user_profiles')
          .insert(profileData);

        let profileError = insertError;

        // If insert fails due to conflict, try upsert
        if (insertError && (insertError.code === '23505' || insertError.message?.includes('duplicate'))) {
          console.log('Profile already exists, using upsert instead');
          const { error: upsertError } = await supabase
            .from('user_profiles')
            .upsert(profileData, {
              onConflict: 'id',
            });
          profileError = upsertError;
        }

        if (profileError) {
          console.error('Error creating/updating profile:', profileError);
          console.error('Profile data that failed:', profileData);
          console.error('Error details:', {
            code: profileError.code,
            message: profileError.message,
            details: profileError.details,
            hint: profileError.hint
          });
          
          // Try one more time with a simple insert (in case upsert syntax is the issue)
          if (profileError.code !== '23505') { // Not a duplicate key error
            console.log('Retrying profile creation with simple insert...');
            const { error: retryError } = await supabase
              .from('user_profiles')
              .insert(profileData);
            
            if (retryError) {
              console.error('Retry also failed:', retryError);
              // Show error but don't block signup - user can still verify email
              // The profile can be created later or manually
            } else {
              console.log('Profile created successfully on retry');
            }
          }
        } else {
          console.log('User profile saved successfully');
          
          // Verify the profile was actually saved
          const { data: verifyProfile, error: verifyError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', signUpData.user.id)
            .single();
          
          if (verifyError) {
            console.error('Error verifying profile creation:', verifyError);
            // Try to create it again if verification fails
            console.log('Attempting to create profile again after verification failed...');
            const { error: recreateError } = await supabase
              .from('user_profiles')
              .insert(profileData);
            
            if (recreateError) {
              console.error('Failed to recreate profile:', recreateError);
            } else {
              console.log('Profile recreated successfully');
            }
          } else if (verifyProfile) {
            console.log('Profile verified in database:', verifyProfile);
          } else {
            console.warn('Profile was not found after creation, attempting to create again...');
            const { error: recreateError } = await supabase
              .from('user_profiles')
              .insert(profileData);
            
            if (recreateError) {
              console.error('Failed to recreate profile:', recreateError);
            } else {
              console.log('Profile created successfully on second attempt');
            }
          }
        }

        // Assign free package to new user
        try {
          const packageResult = await assignFreePackageToUser(signUpData.user.id);
          if (!packageResult.success) {
            console.error('Error assigning free package:', packageResult.error);
            // Log error but don't block signup - user can still verify email and use the app
            // The package can be assigned later if needed
          } else {
            console.log('Free package assigned successfully to new user');
          }
        } catch (packageError) {
          console.error('Error assigning free package:', packageError);
          // Don't block signup if package assignment fails
        }

        // Supabase will automatically send OTP email (8-digit code)
        // No need to manually send email or store OTP in custom table
      }

      // Navigate to verify email page
      navigate('/verify-email', { state: { email: formData.email, purpose: 'email_verification' } });
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex">
      {/* Left Side - Branding */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary to-secondary p-12 relative overflow-hidden">
        <div className="relative z-10 flex flex-col justify-between h-full">
          <div>
            <h1 className="text-5xl font-bold text-white mb-4 leading-tight">
              Build your DNAI<br />
              powered social<br />
              growth engine
            </h1>
            <div className="w-64 h-1 bg-white/90 rounded mb-8"></div>
            <p className="text-white/90 text-lg leading-relaxed">
              Launch your personal DNAI agent to handle content, insights, and<br />
              execution across platforms. Stop reacting. Start controlling your<br />
              social media with data-driven automation.
            </p>
          </div>
          <div className="flex justify-center items-end">
            <img src={characterImage} alt="Character" className="max-w-md w-full h-auto" />
          </div>
        </div>
      </div>

      {/* Right Side - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 lg:p-12 overflow-y-auto">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <CardTitle className="text-3xl font-bold text-foreground">Create your account!</CardTitle>
            <CardDescription className="text-muted-foreground">Tell us a bit about yourself to get started.</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName" className="text-foreground">First Name *</Label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                    <Input
                      id="firstName"
                      name="firstName"
                      type="text"
                      placeholder="Enter your first name"
                      value={formData.firstName}
                      onChange={handleChange}
                      className="pl-10 bg-background text-foreground border-border"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName" className="text-foreground">Last Name *</Label>
                  <Input
                    id="lastName"
                    name="lastName"
                    type="text"
                    placeholder="Enter your last name"
                    value={formData.lastName}
                    onChange={handleChange}
                    className="bg-background text-foreground border-border"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="email" className="text-foreground">Email Address *</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    placeholder="Enter your email"
                    value={formData.email}
                    onChange={handleChange}
                    className="pl-10 bg-background text-foreground border-border"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="phone" className="text-foreground">Phone Number *</Label>
                <div className="flex gap-2">
                  <CountryCodeSelector
                    value={countryCode}
                    onChange={setCountryCode}
                  />
                  <div className="relative flex-1">
                    <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                    <Input
                      id="phone"
                      name="phone"
                      type="tel"
                      placeholder="0123456789"
                      value={formData.phone}
                      onChange={(e) => {
                        // Only allow numbers, max 10 digits
                        const numericValue = e.target.value.replace(/\D/g, '').slice(0, 10);
                        setFormData(prev => ({ ...prev, phone: numericValue }));
                      }}
                      maxLength={10}
                      inputMode="numeric"
                      pattern="[0-9]*"
                      className="pl-10 bg-background text-foreground border-border"
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="password" className="text-foreground">Password *</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                  <Input
                    id="password"
                    name="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="Enter Your Password"
                    value={formData.password}
                    onChange={handleChange}
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
                <p className="text-xs text-muted-foreground">
                  Password must be at least 8 characters and include at least one capital letter
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword" className="text-foreground">Confirm Password *</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                  <Input
                    id="confirmPassword"
                    name="confirmPassword"
                    type={showConfirmPassword ? "text" : "password"}
                    placeholder="Enter Your Confirm Password"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    className="pl-10 pr-10 bg-background text-foreground border-border"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
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
                {loading ? 'Creating Account...' : 'Sign up'}
              </Button>

              <div className="text-center text-sm text-muted-foreground">
                Have an account? <Link to="/" className="text-primary hover:underline font-medium">Sign in</Link>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SignUp;
