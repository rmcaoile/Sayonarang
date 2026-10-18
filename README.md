
# Final Project

**Collaborators:**  

**DEV 1:** CAOILE, Ralph Philip Madera

**DEV 2:** DOMINGO, Reamonn Lois Atibagos

**DEV 3:** MADRID, Reinalyn Andal

**DEV 4:** SILAPAN, Francheska Marie Alipio


**Section:** U-3L

## Program Details

A mobile application depicting a donation system among donors, organizations and admins.

### Features

FOR DONORS:
- Authentication 
    - Sign In and Sign Up
- Browse Organizations
    - List of Organizations accepting donations
- Donation Form
    - Choose categories to donate 
    - Select mode of transportation
    - Input the weight of the items to donate
    - Select Date and Time for pick-up/drop-off
    - Upload photo of the items to donate
- Donation Management
    - Edit, cancel, and delete donations
    - Generate and save QR codes for drop-off donations
- Profile Details
    - View profile details


FOR ORGANIZATIONS:
- Authentication 
    - Sign In and Sign Up
- Donation Management
    - View donations made by the donors
    - Update the status of each donation
- Donation Drives
    - List and manage donation drives
    - Link donations to donation drives
- Profile Management
    - Display and edit organization name and description


FOR ADMIN:
- Authentication 
    - Sign In
- Manage Organizations
    - Approve organization sign-ups
    - View list of organizations
- Manage Donations
    - View list of donations
- Manage Donors
    - View list of donors


### Get Started

##  Download and Install

**Under Github:**
- Download the file via ZIP folder or fork the repository (for self-experimentation).
- Extract the ZIP file to your desired location
-  Navigate to the project folder
- To build and install the app in your own device:

```bash
flutter build apk
```


##  How to use:

### As A Donor:
1. Sign up
    - Create an account by signing up as a donor.
    - Enter your details: name, username, email, password, contact number and address.
2. Navigation
    - Use the bottom navigation bar to navigate through different screens.
3. Home page
    - View all the organizations open for donations.
    - Select an organization you want to donate to.
4. Donation Form
    - Fill out the donation for and click save to submit.
5. Manage Donations
    - View your donations in the middle navigation bar
    - Donations are grouped by status (pending, confirmed, scheduled, completed, and cancelled).
    - Edit, cancel, or delete donations as needed.
6. Profile
    - View your profile details including name and username.
    - Use the logout button to sign out.


### As A Organization:
1. Sign up
    - Create an account by signing up as an organization.
    - Enter your details: name, username, email, password, contact number and address.
2. Navigation
    - Use the bottom navigation bar to navigate through different screens.
3. Home page
    - View all the donations made by the donors.
    - Select a donation you want to link to a donation drive.
4. Manage Donations
    - Select a donation drive you want to link the donation to.
5. Manage Donation Drives
    - View your donation drives in the middle navigation bar.
    - Add a donation drive (requires the admin approval before being able to create).
    - Donation drives are grouped by their status (ongoing or finished).
    - Edit or delete donation drives as needed.
6. Profile
    - View and edit your profile details including name, username, description, address, contact number, status (if accepting donations).
    - Use the logout button to sign out.


### As An Admin:
1. Sign up
    - Sign in the account by entering the correct email and password.
2. Navigation
    - Use the bottom navigation bar to navigate through different screens.
3. Home page
    - View all the organizations.
    - Donations are grouped by their status (pending, approved, rejected).
4. Manage Organizations
    - Approve or reject pending organizations.
5. Manage Donors
    - View all donors.
    - See the donations made by the donors and profile details
6. Profile
    - View the admin details (including information about the developers of the app).
    - Use the logout button to sign out.


<!-- TODO: code cleanup; convert to component repeated elements -->