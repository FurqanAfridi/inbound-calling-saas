import React, { useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  AppBar,
  Toolbar,
  IconButton,
  Typography,
  Box,
  Avatar,
  Menu,
  MenuItem,
  Divider,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import AccountCircleIcon from '@mui/icons-material/AccountCircle';
import LogoutIcon from '@mui/icons-material/Logout';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import ThemeToggle from '../ui/ThemeToggle';

interface HeaderProps {
  onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, signOut } = useAuth();
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [avatarUrl, setAvatarUrl] = React.useState<string | null>(null);

  const getPageTitle = () => {
    const path = location.pathname;
    if (path === '/dashboard') return 'Dashboard';
    if (path === '/create-agent') return 'Create Agent';
    if (path.startsWith('/edit-agent/')) return 'Edit Agent';
    if (path === '/agents') return 'Voice Agents';
    if (path === '/inbound-numbers') return 'Inbound Numbers';
    if (path === '/call-schedules') return 'Call Schedules';
    if (path === '/call-history') return 'Call History';
    if (path === '/leads') return 'Leads';
    if (path === '/billing') return 'Billing & Credits';
    if (path === '/profile') return 'Profile';
    return 'Dashboard';
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = async () => {
    await signOut();
    navigate('/');
    handleMenuClose();
  };

  // Load avatar URL
  useEffect(() => {
    const loadAvatar = async () => {
      if (!user) return;

      try {
        const { data: profile } = await supabase
          .from('user_profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .single();

        if (profile?.avatar_url) {
          setAvatarUrl(profile.avatar_url);
        }
      } catch (error) {
        console.error('Error loading avatar:', error);
      }
    };

    loadAvatar();
  }, [user]);

  return (
    <AppBar
      position="fixed"
      sx={{
        zIndex: (theme) => theme.zIndex.drawer + 1,
        bgcolor: 'background.paper',
        color: 'text.primary',
        borderBottom: '1px solid',
        borderColor: 'grey.200',
        boxShadow: 'none',
        width: '100%',
        top: 0,
        left: 0,
        right: 0,
      }}
    >
      <Toolbar
        sx={{
          minHeight: { xs: '56px', sm: '64px' },
          height: { xs: '56px', sm: '64px' },
          px: { xs: 3, sm: 4, md: 5 },
          justifyContent: 'space-between',
          maxWidth: '1400px',
          mx: 'auto',
          width: '100%',
        }}
      >
        {/* Left side - Menu button (mobile) and Page Title */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flex: 1, minWidth: 0 }}>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={onMenuClick}
            sx={{ 
              display: { md: 'none' },
              mr: { xs: 1 },
            }}
          >
            <MenuIcon />
          </IconButton>

          {/* Page Title */}
          <Typography 
            variant="h6" 
            component="h1" 
            sx={{ 
              fontWeight: 500, 
              fontSize: { xs: '1.25rem', sm: '1.5rem', md: '1.75rem' },
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              flex: 1,
              minWidth: 0,
              color: 'text.primary',
            }}
          >
            {getPageTitle()}
          </Typography>
        </Box>

        {/* Right side - Theme Toggle and User Avatar */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexShrink: 0 }}>
          <ThemeToggle />
          <IconButton
            onClick={handleMenuOpen}
            size="small"
            sx={{ 
              p: 0.5,
            }}
            aria-controls={anchorEl ? 'account-menu' : undefined}
            aria-haspopup="true"
            aria-expanded={anchorEl ? 'true' : undefined}
          >
            <Avatar 
              src={avatarUrl || undefined}
              sx={{ 
                width: { xs: 32, sm: 36 }, 
                height: { xs: 32, sm: 36 }, 
                bgcolor: avatarUrl ? 'transparent' : 'primary.main',
                fontSize: { xs: '0.875rem', sm: '1rem' },
              }}
            >
              {!avatarUrl && (user?.email?.charAt(0).toUpperCase() || 'U')}
            </Avatar>
          </IconButton>
        </Box>

        <Menu
          anchorEl={anchorEl}
          id="account-menu"
          open={Boolean(anchorEl)}
          onClose={handleMenuClose}
          onClick={handleMenuClose}
          transformOrigin={{ horizontal: 'right', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          PaperProps={{
            sx: {
              mt: 1.5,
              minWidth: 200,
              borderRadius: 2,
              boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
            },
          }}
        >
          <Box sx={{ px: 2, py: 1.5 }}>
            <Typography variant="body2" sx={{ fontWeight: 600 }}>
              {user?.email || 'User'}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Admin Account
            </Typography>
          </Box>
          <Divider />
          <MenuItem onClick={() => navigate('/profile')}>
            <AccountCircleIcon sx={{ mr: 2 }} fontSize="small" />
            Profile
          </MenuItem>
          <MenuItem onClick={handleLogout}>
            <LogoutIcon sx={{ mr: 2 }} fontSize="small" />
            Logout
          </MenuItem>
        </Menu>
      </Toolbar>
    </AppBar>
  );
};

export default Header;
