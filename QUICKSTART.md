# DNAi Authentication - Quick Start Guide

## 🚀 Getting Started

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn

### Installation Steps

1. **Extract the project folder**
   - Unzip `dnai-auth-app.zip` to your desired location

2. **Navigate to the project directory**
   ```bash
   cd dnai-auth-app
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```
   Or if you use yarn:
   ```bash
   yarn install
   ```

4. **Start the development server**
   ```bash
   npm start
   ```
   Or with yarn:
   ```bash
   yarn start
   ```

5. **View the application**
   - Open your browser and go to `http://localhost:3000`
   - The Sign In page will be displayed by default

## 📱 Navigation

The application includes these pages:

1. **Sign In** (`/`) - Main login page
2. **Sign Up** (`/signup`) - Registration page
3. **Reset Password** (`/reset-password`) - Password recovery
4. **Verify Email** (`/verify-email`) - OTP verification
5. **Set New Password** (`/set-new-password`) - Password update
6. **Success** (`/success`) - Confirmation screen

## 🎨 Design Features

✅ Exact replica of provided designs
✅ Blue gradient panels with 3D characters
✅ Responsive layout (mobile, tablet, desktop)
✅ Interactive forms with validation states
✅ Social login buttons (Google, Apple, Facebook)
✅ Smooth animations and transitions
✅ Professional typography (Inter font)

## 🛠️ Customization

### Colors
Edit `src/App.css` to change colors:
```css
:root {
  --primary-blue: #3B82F6;
  --dark-text: #1F2937;
  --gray-text: #6B7280;
}
```

### Images
Replace images in `src/assets/` folder:
- Character images (PNG format)
- Logo (PNG format)

### Text Content
Edit component files in `src/components/` to change:
- Headings
- Descriptions
- Button labels
- Form labels

## 📦 Build for Production

```bash
npm run build
```

This creates an optimized production build in the `build/` folder.

## 🔧 Troubleshooting

### Port already in use
If port 3000 is busy, React will ask to use another port (3001, etc.)

### Images not loading
Make sure all images are in `src/assets/` folder

### Styling issues
Clear browser cache or do a hard refresh (Ctrl+Shift+R)

## 📞 Support

For any issues or questions, please refer to the README.md file.

---

**Built with ❤️ for DNAi (Duha Nashrah)**
