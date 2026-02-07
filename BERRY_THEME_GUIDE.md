# Berry Theme Integration Guide

This project now uses the **Berry Free React Admin Template** theme from [GitHub](https://github.com/codedthemes/berry-free-react-admin-template.git) for all dashboard and admin pages.

## 🎨 Theme Overview

The Berry theme provides:
- Modern Material-UI (MUI) components
- Consistent design system
- Responsive layout
- Professional admin dashboard appearance

## 📦 Installed Packages

- `@mui/material` - Material-UI core components
- `@mui/icons-material` - Material-UI icons
- `@emotion/react` - CSS-in-JS library (required by MUI)
- `@emotion/styled` - Styled components (required by MUI)

## 🏗️ Project Structure

```
src/
├── theme/
│   └── index.ts              # Berry theme configuration
├── components/
│   ├── layout/
│   │   ├── MainLayout.tsx    # Main layout wrapper with sidebar & header
│   │   ├── Sidebar.tsx       # Navigation sidebar
│   │   └── Header.tsx        # Top header bar
│   ├── Dashboard.tsx         # Dashboard page (Berry themed)
│   ├── CreateVoiceAgent.tsx  # Create agent page (Berry themed)
│   └── BerryPageTemplate.tsx # Template for new pages
```

## 🚀 Creating New Pages

### Step 1: Use MainLayout

Wrap your page content with `MainLayout`:

```tsx
import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';
import MainLayout from './layout/MainLayout';

const MyNewPage: React.FC = () => {
  return (
    <MainLayout>
      <Box>
        <Typography variant="h4" fontWeight={600}>
          My New Page
        </Typography>
        <Card>
          <CardContent>
            {/* Your content here */}
          </CardContent>
        </Card>
      </Box>
    </MainLayout>
  );
};

export default MyNewPage;
```

### Step 2: Use Material-UI Components

Use MUI components instead of custom HTML/CSS:

- **Layout**: `Box`, `Grid`, `Container`
- **Typography**: `Typography`
- **Forms**: `TextField`, `Select`, `Button`, `Checkbox`
- **Data Display**: `Card`, `Table`, `Chip`, `Avatar`
- **Feedback**: `Alert`, `Dialog`, `Snackbar`
- **Navigation**: `Tabs`, `Breadcrumbs`

### Step 3: Follow Berry Design Patterns

1. **Page Headers**: Use `Typography variant="h4"` with `fontWeight={600}`
2. **Cards**: Use `Card` component with `CardContent`
3. **Spacing**: Use MUI's spacing system (`sx={{ mb: 3 }}`, `spacing={3}`)
4. **Colors**: Use theme colors (`primary`, `success`, `error`, `warning`)
5. **Buttons**: Use `variant="contained"` for primary actions

## 🎨 Theme Colors

The Berry theme provides these colors:

- **Primary**: `#5E72E4` (Blue)
- **Success**: `#2DCE89` (Green)
- **Error**: `#F5365C` (Red)
- **Warning**: `#FB6340` (Orange)
- **Info**: `#11CDEF` (Cyan)
- **Secondary**: `#8392AB` (Gray)

Access them via:
```tsx
sx={{ bgcolor: 'primary.main', color: 'success.main' }}
```

## 📱 Responsive Design

Use MUI's Grid system for responsive layouts:

```tsx
<Grid container spacing={3}>
  <Grid item xs={12} sm={6} md={4}>
    {/* Content */}
  </Grid>
</Grid>
```

Breakpoints:
- `xs`: Extra small (mobile)
- `sm`: Small (tablet)
- `md`: Medium (desktop)
- `lg`: Large (wide desktop)
- `xl`: Extra large

## 🔧 Common Patterns

### Stats Cards
```tsx
<Card>
  <CardContent>
    <Box display="flex" alignItems="center" justifyContent="space-between">
      <Box>
        <Typography variant="body2" color="text.secondary">
          Label
        </Typography>
        <Typography variant="h4" fontWeight={600}>
          Value
        </Typography>
      </Box>
      <Avatar sx={{ bgcolor: 'primary.main' }}>
        <Icon />
      </Avatar>
    </Box>
  </CardContent>
</Card>
```

### Form Layout
```tsx
<Grid container spacing={3}>
  <Grid item xs={12} sm={6}>
    <TextField fullWidth label="Field 1" />
  </Grid>
  <Grid item xs={12} sm={6}>
    <TextField fullWidth label="Field 2" />
  </Grid>
</Grid>
```

### Action Buttons
```tsx
<Box display="flex" justifyContent="flex-end" gap={2}>
  <Button variant="outlined">Cancel</Button>
  <Button variant="contained">Submit</Button>
</Box>
```

## 📚 Resources

- [Material-UI Documentation](https://mui.com/)
- [Berry Template GitHub](https://github.com/codedthemes/berry-free-react-admin-template)
- [Berry Live Demo](https://berrydashboard.com/free/)

## ✅ Updated Pages

- ✅ Dashboard - Now uses Berry theme
- ✅ CreateVoiceAgent - Now uses Berry theme
- ✅ All future pages should follow this pattern

## 🎯 Best Practices

1. Always use `MainLayout` for admin pages
2. Use MUI components instead of custom HTML
3. Follow the spacing system (multiples of 8px)
4. Use theme colors instead of hardcoded colors
5. Make components responsive using Grid system
6. Use Typography variants for consistent text styling
