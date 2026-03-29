// Usage: node create_staff_accounts.js
// Creates proctorial and security staff accounts in the Firebase project
// Make sure to run this in a trusted environment with serviceAccountKey.json in this folder

const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase with service account
try {
  const serviceAccount = JSON.parse(fs.readFileSync('serviceAccountKey.json', 'utf8'));
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
} catch (error) {
  console.error('Error loading serviceAccountKey.json:', error.message);
  console.error('Please ensure serviceAccountKey.json is in the functions folder');
  process.exit(1);
}

// ============= CUSTOMIZE THESE ACCOUNTS =============
// Add all Proctorial Body members here
// NOTE: Staff can use ANY email domain (Gmail, Yahoo, Outlook, etc.)
const proctorialAccounts = [
  { 
    email: 'saniaislam2811@gmail.com',  // Sania Islam - Proctor
    password: 'Sania@2811', 
    name: 'Sania Islam', 
    designation: 'Proctor',
    phone: '+8801712345678',
    role: 'proctorial' 
  },
  { 
    email: 'saniasultana825@gmail.com',  // Sania Sultana - Proctor
    password: 'Sania@825', 
    name: 'Sania Sultana', 
    designation: 'Proctor',
    phone: '+8801800000000',
    role: 'proctorial' 
  },
];

// Add all Security Body members here
// NOTE: Staff can use ANY email domain (Gmail, Yahoo, Outlook, etc.)
const securityAccounts = [
  { 
    email: 'juktadas01@gmail.com',      // Jukta Das - Security Officer
    password: 'Jukta@2025', 
    name: 'Jukta Das', 
    designation: 'Security Officer',
    phone: '+8801812345679',
    role: 'security' 
  },
];

const accounts = [...proctorialAccounts, ...securityAccounts];
// ====================================================

async function create() {
  console.log(`\n🔐 Creating ${accounts.length} staff accounts...\n`);
  
  let created = 0;
  let updated = 0;
  let failed = 0;

  for (const a of accounts) {
    try {
      const user = await admin.auth().getUserByEmail(a.email).catch(() => null);
      let uid;
      
      if (!user) {
        const created_user = await admin.auth().createUser({
          email: a.email,
          password: a.password,
          displayName: a.name,
        });
        uid = created_user.uid;
        console.log(`✅ Created user: ${a.email} (${a.role})`);
        created++;
      } else {
        uid = user.uid;
        // Update password if user already exists
        await admin.auth().updateUser(uid, { password: a.password });
        console.log(`🔄 Updated user: ${a.email} (${a.role})`);
        updated++;
      }

      // Save user document in Firestore
      await admin.firestore().collection('users').doc(uid).set({
        name: a.name,
        email: a.email,
        role: a.role,
        designation: a.designation || '',
        phone: a.phone || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log(`   Saved to Firestore: ${a.email}\n`);
    } catch (err) {
      console.error(`❌ Error for ${a.email}:`, err.message);
      failed++;
    }
  }

  console.log('\n' + '='.repeat(50));
  console.log('📊 Summary:');
  console.log(`   Created: ${created}`);
  console.log(`   Updated: ${updated}`);
  console.log(`   Failed: ${failed}`);
  console.log('='.repeat(50));
  console.log('\n✨ Staff accounts setup complete!\n');
  console.log('📝 Login Credentials:');
  console.log('   Proctorial Body:');
  proctorialAccounts.forEach(a => console.log(`      ${a.email} / ${a.password}`));
  console.log('   Security Body:');
  securityAccounts.forEach(a => console.log(`      ${a.email} / ${a.password}`));
  console.log('\n');
}

create().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});