# DNAi Authentication App

A complete authentication system for DNAi (Duha Nashrah) with 6 beautifully designed screens.

## Features

- **Sign In** - User login with email, password, and social login options (Google, Apple, Facebook)
- **Sign Up** - User registration with complete form validation
- **Reset Password** - Email-based password reset flow
- **Verify Email** - OTP verification with 6-digit code input
- **Set New Password** - Password update interface
- **Success** - Confirmation screen after successful password update

## Design Highlights

- Exact replica of the provided designs
- Blue gradient left panel with 3D character illustrations
- Clean white form panels with modern UI
- Fully responsive layout
- Smooth transitions and hover effects
- Professional typography using Inter font
- Social login integration (Google, Apple, Facebook)

## Tech Stack

- React 18
- React Router v6
- CSS3 with custom properties
- Google Fonts (Inter)

## Installation

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm start
```

3. Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

## Available Routes

- `/` - Sign In page
- `/signup` - Sign Up page
- `/reset-password` - Reset Password page
- `/verify-email` - Email Verification page
- `/set-new-password` - Set New Password page
- `/success` - Success confirmation page

## Project Structure

```
dnai-auth-app/
├── public/
│   └── index.html
├── src/
│   ├── assets/
│   │   └── [All 3D character images and logos]
│   ├── components/
│   │   ├── SignIn.js
│   │   ├── SignUp.js
│   │   ├── ResetPassword.js
│   │   ├── VerifyEmail.js
│   │   ├── SetNewPassword.js
│   │   └── Success.js
│   ├── App.js
│   ├── App.css
│   ├── index.js
│   └── index.css
└── package.json
```

## Customization

All styling is centralized in `App.css` with CSS custom properties for easy theming:

```css
--primary-blue: #3B82F6;
--dark-text: #1F2937;
--gray-text: #6B7280;
--light-gray: #F3F4F6;
--border-gray: #E5E7EB;
--white: #FFFFFF;
--success-green: #10B981;
```

## Build for Production

```bash
npm run build
```

This creates an optimized production build in the `build` folder.

## Notes

- All 3D character images and logos are included in the `src/assets` folder
- The design exactly matches the provided screenshots
- Forms include proper validation states and interactive elements
- Social login buttons are styled but require backend integration
- Responsive design works on all screen sizes

## License

All rights reserved - DNAi (Duha Nashrah)
