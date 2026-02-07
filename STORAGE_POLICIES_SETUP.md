# Storage Policies Setup Guide

## ⚠️ Important: Storage Policies Cannot Be Created via SQL

The `storage.objects` table is a system table in Supabase, and you cannot create policies on it directly via SQL unless you have superuser/owner privileges. 

**Solution**: Create storage policies through the Supabase Dashboard UI instead.

---

## 📋 Step-by-Step: Create Storage Policies via Dashboard

### Method 1: Using Supabase Dashboard (Recommended)

#### For Avatars Bucket:

1. **Go to Storage in Supabase Dashboard**
   - Navigate to your Supabase project
   - Click on **Storage** in the left sidebar

2. **Select the `avatars` bucket**
   - Click on the `avatars` bucket

3. **Go to Policies tab**
   - Click on the **Policies** tab at the top

4. **Create New Policy for INSERT (Upload)**
   - Click **New Policy**
   - Policy name: `Users can upload their own avatars`
   - Allowed operation: **INSERT**
   - Policy definition (SQL):
   ```sql
   (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])
   ```
   - Click **Review** then **Save policy**

5. **Create New Policy for UPDATE**
   - Click **New Policy**
   - Policy name: `Users can update their own avatars`
   - Allowed operation: **UPDATE**
   - Policy definition (SQL):
   ```sql
   (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])
   ```
   - Click **Review** then **Save policy**

6. **Create New Policy for DELETE**
   - Click **New Policy**
   - Policy name: `Users can delete their own avatars`
   - Allowed operation: **DELETE**
   - Policy definition (SQL):
   ```sql
   (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])
   ```
   - Click **Review** then **Save policy**

7. **Create New Policy for SELECT (Public Read)**
   - Click **New Policy**
   - Policy name: `Avatars are publicly readable`
   - Allowed operation: **SELECT**
   - Policy definition (SQL):
   ```sql
   (bucket_id = 'avatars')
   ```
   - Click **Review** then **Save policy**

#### For KYC Documents Bucket:

1. **Select the `kyc-documents` bucket**
   - Click on the `kyc-documents` bucket

2. **Go to Policies tab**
   - Click on the **Policies** tab

3. **Create INSERT Policy**
   - Policy name: `Users can upload their own KYC documents`
   - Operation: **INSERT**
   - Policy: `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])`

4. **Create SELECT Policy**
   - Policy name: `Users can view their own KYC documents`
   - Operation: **SELECT**
   - Policy: `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])`

5. **Create UPDATE Policy**
   - Policy name: `Users can update their own KYC documents`
   - Operation: **UPDATE**
   - Policy: `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])`

6. **Create DELETE Policy**
   - Policy name: `Users can delete their own KYC documents`
   - Operation: **DELETE**
   - Policy: `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])`

---

### Method 2: Using Supabase CLI (Alternative)

If you have Supabase CLI installed and configured:

```bash
# Create policies file
cat > storage-policies.sql << 'EOF'
-- Avatar policies
CREATE POLICY "Users can upload their own avatars"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

CREATE POLICY "Users can update their own avatars"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

CREATE POLICY "Users can delete their own avatars"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

CREATE POLICY "Avatars are publicly readable"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- KYC policies
CREATE POLICY "Users can upload their own KYC documents"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

CREATE POLICY "Users can view their own KYC documents"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

CREATE POLICY "Users can update their own KYC documents"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])
    WITH CHECK (bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1]);

CREATE POLICY "Users can delete their own KYC documents"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1]);
EOF

# Apply via Supabase CLI (if you have local project)
supabase db reset
```

---

### Method 3: Using Service Role Key (Advanced - Not Recommended)

If you have access to the service role key, you can create a temporary script to run the policies. However, this is **NOT RECOMMENDED** for security reasons.

---

## ✅ Quick Reference: Policy Definitions

### Avatars Bucket Policies:

| Operation | Policy Name | Policy Definition |
|-----------|-------------|-------------------|
| INSERT | Users can upload their own avatars | `(bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |
| UPDATE | Users can update their own avatars | `(bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |
| DELETE | Users can delete their own avatars | `(bucket_id = 'avatars' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |
| SELECT | Avatars are publicly readable | `(bucket_id = 'avatars')` |

### KYC Documents Bucket Policies:

| Operation | Policy Name | Policy Definition |
|-----------|-------------|-------------------|
| INSERT | Users can upload their own KYC documents | `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |
| SELECT | Users can view their own KYC documents | `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |
| UPDATE | Users can update their own KYC documents | `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |
| DELETE | Users can delete their own KYC documents | `(bucket_id = 'kyc-documents' AND auth.uid()::text = (string_to_array(name, '/'))[1])` |

---

## 🧪 Testing After Setup

1. **Test Avatar Upload**:
   - Go to Profile → Profile tab
   - Upload an avatar
   - Should work without RLS errors

2. **Test KYC Upload**:
   - Go to Profile → Verification tab
   - Upload KYC documents
   - Should work without RLS errors

---

## 🔍 Troubleshooting

### Error: "Policy already exists"
- Delete the existing policy first, then create a new one
- Or update the existing policy with the correct definition

### Error: "Invalid policy definition"
- Make sure you're using the exact policy definitions from the table above
- Check that bucket names match exactly: `'avatars'` and `'kyc-documents'`

### Error: "RLS is not enabled"
- Go to Storage → Settings
- Make sure "Row Level Security" is enabled for the bucket

---

## 📝 Notes

- **File Path Format**: Policies expect files to be stored as `{user_id}/filename.ext`
- **Public vs Private**: Avatars are public (anyone can read), KYC documents are private (only owner can read)
- **Policy Evaluation**: Policies are evaluated for each operation (INSERT, SELECT, UPDATE, DELETE)
