import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import '../App.css';
import characterImage from '../assest/resetpassword.png';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';
import { emailService } from '../services/emailService';

const SetNewPassword: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { updatePassword } = useAuth();
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState<boolean>(false);
  const [password, setPassword] = useState<string>('');
  const [confirmPassword, setConfirmPassword] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    if (!location.state?.email) {
      navigate('/reset-password');
    }
  }, [location, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!password || !confirmPassword) {
      setError('Please enter both password fields');
      return;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);

    try {
      const { error: updateError } = await updatePassword(password);

      if (updateError) {
        setError(updateError.message || 'Failed to update password');
        setLoading(false);
        return;
      }

      // Store password in history
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        // In production, hash the password before storing
        await supabase
          .from('password_history')
          .insert({
            user_id: user.id,
            password_hash: password, // Should be hashed in production
          });

        // Create notification
        await supabase.rpc('create_notification', {
          p_user_id: user.id,
          p_type: 'password_changed',
          p_title: 'Password Changed',
          p_message: 'Your password has been successfully changed.',
        });

        // Send password changed email notification
        if (user.email) {
          await emailService.sendPasswordChangedEmail(user.email);
        }
      }

      navigate('/success', { state: { message: 'Password Updated!' } });
    } catch (err: any) {
      setError(err.message || 'An error occurred');
      setLoading(false);
    }
  };

  return (
    <div className="centered-container">
      <div className="centered-content">
        <div className="centered-image">
          <img src={characterImage} alt="Character" />
        </div>

        <div className="centered-form">
          <form className="form-container" onSubmit={handleSubmit}>
            <h2 className="form-title">Set a New Password.</h2>
            <p className="form-subtitle">
              Create a new password to continue.
            </p>

            <div className="form-group">
              <label>Enter New Password</label>
              <div className="input-with-icon">
                <input
                  type={showPassword ? "text" : "password"}
                  placeholder="Enter Your New Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
                <span 
                  className="input-icon"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? '👁️' : '👁️‍🗨️'}
                </span>
              </div>
            </div>

            <div className="form-group">
              <label>Confirm Password</label>
              <div className="input-with-icon">
                <input
                  type={showConfirmPassword ? "text" : "password"}
                  placeholder="Enter Your Confirm Password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                />
                <span 
                  className="input-icon"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                >
                  {showConfirmPassword ? '👁️' : '👁️‍🗨️'}
                </span>
              </div>
            </div>

            {error && <div className="error-message">{error}</div>}
            <button 
              type="submit"
              className="submit-button" 
              disabled={loading}
            >
              {loading ? 'Updating...' : 'Done'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default SetNewPassword;
