# Review Submission Fix Guide

## Issues Fixed

### 1. **Collection Reference Bug** ✅
- **Problem**: Review submission was looking for user data in `customers` collection but users are stored in `users` collection
- **Fix**: Updated the collection reference from `'customers'` to `'users'` in the `_submit()` method

### 2. **UI Layout Bug** ✅  
- **Problem**: TextButton.icon had swapped `icon` and `label` parameters
- **Fix**: Corrected the parameter order so the arrow icon displays before the "Show Less/All" text

## Firestore Setup Required

### Collections Needed:
Your Firestore database needs these collections:

1. **`users`** - User profile data
   - Fields: `name`, `email`, `phone`, `address`, `photoUrl`, etc.

2. **`vehicles`** - Car listings
   - Fields: `name`, `model`, `category`, `seats`, `fuel`, `transmission`, `dailyRate`, `status`, `plateNumber`, `imageUrl`

3. **`reviews`** - Customer reviews (NEW)
   - Fields: 
     - `vehicleId` (string) - ID of the car being reviewed
     - `uid` (string) - User ID of the reviewer
     - `displayName` (string) - Reviewer's display name
     - `email` (string) - Reviewer's email
     - `photoUrl` (string) - Reviewer's profile photo
     - `rating` (number) - Star rating (1-5)
     - `comment` (string) - Review text
     - `createdAt` (timestamp) - Server timestamp
     - `updatedAt` (timestamp) - Last update timestamp

### Firestore Security Rules

Add these rules to your Firestore **Security Rules** (in Firebase Console):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read their own data and public data
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth.uid == userId;
    }

    // Allow reading vehicle data
    match /vehicles/{vehicleId} {
      allow read: if true;
      allow write: if false; // Only admin can write
    }

    // Allow reading and writing reviews
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.uid;
      allow delete: if request.auth.uid == resource.data.uid;
    }
  }
}
```

## How to Test

1. **Sign up / Log in** as a customer
2. **Navigate to a car** and click "View Details"
3. **Scroll to Reviews section**
4. **Write a review** with rating and comment
5. **Click "Submit Review"** button
6. Review should appear in the list immediately
7. Check Firebase Console → Firestore → Collections → `reviews` to verify data is stored

## Firestore Console Setup Steps

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. Create collection `reviews` if it doesn't exist (auto-created on first write)
5. Update **Security Rules** with the rules above
6. Deploy the rules

## Troubleshooting

### "Could not submit review" Error
- **Check 1**: Verify Firestore security rules allow writes to `reviews` collection
- **Check 2**: Ensure user is authenticated (signed in)
- **Check 3**: Check Firebase Console → Firestore → Indexes (may need to create a composite index)

### Composite Index Required
If you see an error about needing a composite index, click the link in the Firebase Console error message to auto-create it. It needs to index on:
- `vehicleId` (Ascending)
- `createdAt` (Descending)

### Reviews Not Showing
- Check Firestore → Collections → `reviews` to see if documents are being created
- Verify `vehicleId` in stored reviews matches the current car's ID
- Check browser console (F12) for any JavaScript errors

## Files Modified
- `lib/pages/customer/car_details_page.dart` - Fixed collection reference and UI layout
