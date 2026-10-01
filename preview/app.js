// Wehere - Interactive Web Showcase & Device Simulator

let currentScreen = 'splash';
let currentDevice = 'ios';
let swipeCardIndex = 0;
let userAnonymous = false;
let currentOnboardingStep = 1;

// Active User Profile State (Initialized & Dynamic)
const currentUser = {
  id: '@alex_7294',
  name: 'Alex Rivera',
  email: 'alex@wehere.com',
  age: 24,
  location: 'Mumbai, India',
  bio: 'Learning to be kind to myself one day at a time. 🌱',
  interests: ['Mindfulness', 'Reading', 'Music', 'Personal Growth'],
  feelings: ['Burnout', 'Lonely'],
  lookingFor: ['Someone to Talk To', 'Emotional Support'],
  isAnonymous: false,
  streakDays: 16,
  xp: 2350,
  level: 12,
  avatarUrl: '../assets/mockups/user_dashboard_alex.jpeg'
};

const idHandlesPool = [
  '@gentle_river_42',
  '@calm_nebula_88',
  '@quiet_compass_19',
  '@mindful_lotus_77',
  '@serene_ember_33',
  '@alex_growth_94',
  '@brave_spirit_11'
];

function generateRandomHandle() {
  return idHandlesPool[Math.floor(Math.random() * idHandlesPool.length)];
}

const cardsData = [
  {
    name: 'Riya, 24',
    verified: true,
    location: 'Mumbai, India',
    online: true,
    mood: 'Healing & Growing 💜',
    bio: 'Learning to be kind to myself one day at a time. Navigating burnout with self-compassion. 💜',
    interests: 'Reading, Nature, Music, Journaling',
    lookingFor: 'Meaningful conversations & a listening friend',
    matchPct: 94,
    compatibilityReason: 'Both navigating burnout & love reading. Kind growth alignment 🌱',
    img: '../assets/mockups/discover_swipe.jpeg'
  },
  {
    name: 'Rohan, 26',
    verified: true,
    location: 'Delhi, India',
    online: true,
    mood: 'Calm & Reflective 🌿',
    bio: 'Balancing tech career pressure with mindful habits and fitness.',
    interests: 'Mindfulness, Fitness, Tech, Reading',
    lookingFor: 'Accountability partner & positive vibes',
    matchPct: 90,
    compatibilityReason: 'Both value mindfulness and daily personal growth habits. 🌿',
    img: '../assets/mockups/home_dashboard_priya.jpeg'
  },
  {
    name: 'Meera, 24',
    verified: true,
    location: 'Bengaluru, India',
    online: true,
    mood: 'Taking it day by day ☕',
    bio: 'Art enthusiast. Navigating burnout and learning quiet self-compassion.',
    interests: 'Painting, Journaling, Coffee, Music',
    lookingFor: 'Empathetic friend to share quiet thoughts with',
    matchPct: 96,
    compatibilityReason: 'Shared struggles with burnout & common passion for music. Empathetic match 💜',
    img: '../assets/mockups/profile_detail.jpeg'
  }
];

function recalculateMatches() {
  cardsData.forEach(card => {
    const cardInterests = card.interests.toLowerCase();
    const common = currentUser.interests.filter(i => cardInterests.includes(i.toLowerCase()));
    const sharesStruggles = currentUser.feelings.some(f => card.bio.toLowerCase().includes(f.toLowerCase()) || card.mood.toLowerCase().includes(f.toLowerCase()));

    let base = 85 + (common.length * 3);
    if (sharesStruggles) base += 6;
    card.matchPct = Math.min(Math.max(base, 84), 98);

    if (sharesStruggles && common.length > 0) {
      card.compatibilityReason = `Both navigating ${currentUser.feelings[0].toLowerCase()} & love ${common[0]}. Empathetic alignment 💜`;
    } else if (common.length > 0) {
      card.compatibilityReason = `You both connect on ${common.slice(0, 2).join(' & ')}. Kind growth alignment 🌱`;
    } else {
      card.compatibilityReason = `Empathetic listener match. Sharing positive peer support 💜`;
    }
  });
}

function showToast(msg) {
  const existing = document.getElementById('toast-notification');
  if (existing) existing.remove();
  const phone = document.getElementById('phone-frame');
  if (!phone) return;
  const toast = document.createElement('div');
  toast.id = 'toast-notification';
  toast.className = 'toast-notification';
  toast.innerHTML = `<span>✨</span><span>${msg}</span>`;
  phone.appendChild(toast);
  setTimeout(() => {
    if (toast && toast.parentElement) toast.remove();
  }, 3000);
}


const mockupsList = [
  { name: '1. Brand Splash', file: '../assets/mockups/brand_splash.jpeg' },
  { name: '2. Walkthrough (Meaningful)', file: '../assets/mockups/walkthrough_meaningful_connections.jpeg' },
  { name: '3. Walkthrough (Safe & Secure)', file: '../assets/mockups/walkthrough_safe_secure.jpeg' },
  { name: '4. Walkthrough (Grow Together)', file: '../assets/mockups/walkthrough_grow_together.jpeg' },
  { name: '5. Walkthrough (Not Alone)', file: '../assets/mockups/walkthrough_not_alone.jpeg' },
  { name: '6. Auth Log In', file: '../assets/mockups/auth_login.jpeg' },
  { name: '7. Auth Sign Up', file: '../assets/mockups/auth_signup.jpeg' },
  { name: '8. OTP Email Verification', file: '../assets/mockups/auth_otp_verify.jpeg' },
  { name: '9. Intake: Profile Info', file: '../assets/mockups/onboarding_profile_info.jpeg' },
  { name: '10. Intake: Interests', file: '../assets/mockups/onboarding_interests.jpeg' },
  { name: '11. Intake: Feelings Lately', file: '../assets/mockups/onboarding_feelings_lately.jpeg' },
  { name: '12. Intake: Looking For', file: '../assets/mockups/onboarding_looking_for.jpeg' },
  { name: '13. Intake: Photos & Anonymity', file: '../assets/mockups/onboarding_photos_anonymity.jpeg' },
  { name: '14. Intake: Notifications', file: '../assets/mockups/onboarding_notifications.jpeg' },
  { name: '15. Intake: All Set Summary', file: '../assets/mockups/onboarding_summary.jpeg' },
  { name: '16. Home Dashboard (Priya)', file: '../assets/mockups/home_dashboard_priya.jpeg' },
  { name: '17. Home Dashboard (Good Morning)', file: '../assets/mockups/good_morning_home.jpeg' },
  { name: '18. Home Dashboard (Explore)', file: '../assets/mockups/explore_categories.jpeg' },
  { name: '19. Discover: Swipe Deck', file: '../assets/mockups/discover_swipe.jpeg' },
  { name: '20. Discover: User Profile Detail', file: '../assets/mockups/profile_detail.jpeg' },
  { name: '21. Celebration: It\'s a Match!', file: '../assets/mockups/match_celebration.jpeg' },
  { name: '22. Safe Peer Chat (Riya)', file: '../assets/mockups/chat_screen.jpeg' },
  { name: '23. Journal: New Entry Screen', file: '../assets/mockups/journal_new_entry.jpeg' },
  { name: '24. Journal: Save Bottom Sheet', file: '../assets/mockups/journal_save_sheet.jpeg' },
  { name: '25. Journal: All Set Confirmation', file: '../assets/mockups/journal_all_set.jpeg' },
  { name: '26. Progress: Donut Analytics', file: '../assets/mockups/progress_analytics.jpeg' },
  { name: '27. Progress: Achievements & Badges', file: '../assets/mockups/achievements_insights.jpeg' },
  { name: '28. Community: Circles & Feed', file: '../assets/mockups/community_feed.jpeg' },
  { name: '29. SOS Emergency Help Hub', file: '../assets/mockups/sos_help.jpeg' },
  { name: '30. Profile & Gamification (Alex)', file: '../assets/mockups/user_dashboard_alex.jpeg' },
  { name: '31. Walkthrough Welcome Safe', file: '../assets/mockups/walkthrough_welcome_safe.jpeg' },
  { name: '32. Onboarding Goals', file: '../assets/mockups/onboarding_goals.jpeg' }
];

function switchDevice(device) {
  currentDevice = device;
  const frame = document.getElementById('phone-frame');
  document.getElementById('btn-ios').classList.toggle('active', device === 'ios');
  document.getElementById('btn-android').classList.toggle('active', device === 'android');

  if (device === 'android') {
    frame.className = 'phone-frame android';
  } else {
    frame.className = 'phone-frame ios';
  }
}

function loadScreen(screenId) {
  currentScreen = screenId;
  const viewport = document.getElementById('screen-viewport');
  
  // Highlight sidebar
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.classList.toggle('active', btn.getAttribute('onclick')?.includes(screenId));
  });

  switch (screenId) {
    case 'splash':
      viewport.innerHTML = renderSplash();
      break;
    case 'walkthrough':
      viewport.innerHTML = renderWalkthrough();
      break;
    case 'login':
      viewport.innerHTML = renderLogin();
      break;
    case 'signup':
      viewport.innerHTML = renderSignUp();
      break;
    case 'otp':
      viewport.innerHTML = renderOtp();
      break;
    case 'onboarding':
      viewport.innerHTML = renderOnboarding();
      break;
    case 'home':
      viewport.innerHTML = renderHome();
      break;
    case 'discover':
      viewport.innerHTML = renderDiscover();
      initSwipePhysics();
      break;
    case 'match_modal':
      viewport.innerHTML = renderMatchCelebration();
      break;
    case 'chat':
      viewport.innerHTML = renderChat();
      break;
    case 'journal_new':
      viewport.innerHTML = renderJournalNew();
      break;
    case 'journal_done':
      viewport.innerHTML = renderJournalDone();
      break;
    case 'progress':
      viewport.innerHTML = renderProgress();
      break;
    case 'community':
      viewport.innerHTML = renderCommunity();
      break;
    case 'sos':
      viewport.innerHTML = renderSos();
      break;
    case 'campus':
      viewport.innerHTML = renderCampusCorporate();
      break;
    case 'profile':
      viewport.innerHTML = renderProfile();
      break;
    default:
      viewport.innerHTML = renderHome();
  }
}

// 1. SPLASH SCREEN (Mockup 1.17.26 AM (2))
function renderSplash() {
  return `
    <div style="height:100%; background: linear-gradient(180deg, #7A62F8 0%, #5E4BEE 50%, #4C3ADB 100%); color:#fff; display:flex; flex-direction:column; justify-content:space-between; padding: 24px;">
      <div style="flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center;">
        <div style="width:110px; height:110px; background:#FFF; border-radius:50%; display:flex; align-items:center; justify-content:center; box-shadow:0 10px 30px rgba(0,0,0,0.15); margin-bottom:24px; position:relative;">
          <svg viewBox="0 0 24 24" width="60" height="60" fill="#5E4BEE"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
          <div style="position:absolute; top:20px; right:20px; font-size:22px;">🌱</div>
        </div>
        <h1 style="font-size:36px; font-weight:800; font-family:serif; letter-spacing:0.5px;">We Here</h1>
        <div style="display:flex; align-items:center; gap:8px; margin: 12px 0;">
          <div style="width:32px; height:1px; background:rgba(255,255,255,0.4);"></div>
          <span style="color:rgba(255,255,255,0.8); font-size:13px;">♥</span>
          <div style="width:32px; height:1px; background:rgba(255,255,255,0.4);"></div>
        </div>
        <p style="font-size:17px; font-weight:600; text-align:center; line-height:1.4;">A safe place to talk,<br>connect and heal.</p>
        <p style="font-style:italic; font-size:14px; margin-top:10px; opacity:0.85;">You're not alone. ♡</p>
      </div>

      <div>
        <button onclick="loadScreen('walkthrough')" style="width:100%; height:54px; background:#FFF; color:#5E4BEE; border:none; border-radius:28px; font-size:16px; font-weight:700; cursor:pointer; box-shadow:0 8px 24px rgba(0,0,0,0.15); display:flex; align-items:center; justify-content:center; gap:8px;">
          Get Started ➔
        </button>
        <div style="display:flex; justify-content:center; gap:6px; margin-top:16px;">
          <span style="width:18px; height:8px; background:#FFF; border-radius:4px;"></span>
          <span style="width:8px; height:8px; background:rgba(255,255,255,0.4); border-radius:50%;"></span>
          <span style="width:8px; height:8px; background:rgba(255,255,255,0.4); border-radius:50%;"></span>
        </div>
      </div>
    </div>
  `;
}

// 2. WALKTHROUGH SLIDES
function renderWalkthrough() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; padding:16px 20px; background:#F8F8FD;">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <button onclick="loadScreen('splash')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
        <button onclick="loadScreen('login')" style="background:none; border:none; color:#5E4BEE; font-weight:700; cursor:pointer;">Skip</button>
      </div>

      <div style="flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center;">
        <div style="width:220px; height:220px; border-radius:50%; background:#F0EEFF; display:flex; align-items:center; justify-content:center; margin-bottom:28px; position:relative; box-shadow:0 12px 30px rgba(94,75,238,0.1);">
          <span style="font-size:84px;">💜</span>
          <div style="position:absolute; bottom:20px; right:30px; font-size:36px;">🌱</div>
        </div>
        <h2 style="font-size:24px; font-weight:800; color:#191632;">Find Meaningful Connections 💜</h2>
        <p style="font-size:14px; color:#6B6984; margin-top:8px; max-width:280px; line-height:1.4;">
          Connect with empathetic people who understand your journey and support you without judgment.
        </p>
      </div>

      <div style="display:flex; justify-content:center; gap:6px; margin-bottom:24px;">
        <span style="width:20px; height:8px; background:#5E4BEE; border-radius:4px;"></span>
        <span style="width:8px; height:8px; background:#ECEBF7; border-radius:50%;"></span>
        <span style="width:8px; height:8px; background:#ECEBF7; border-radius:50%;"></span>
        <span style="width:8px; height:8px; background:#ECEBF7; border-radius:50%;"></span>
      </div>

      <button onclick="loadScreen('login')" style="width:100%; height:54px; background:#5E4BEE; color:#FFF; border:none; border-radius:28px; font-size:16px; font-weight:700; cursor:pointer; box-shadow:0 8px 20px rgba(94,75,238,0.35); margin-bottom:12px;">
        Next ➔
      </button>
      <p style="text-align:center; font-size:13px; color:#6B6984;">
        Already have an account? <span onclick="loadScreen('login')" style="color:#5E4BEE; font-weight:700; cursor:pointer;">Log In</span>
      </p>
    </div>
  `;
}

// 3. LOG IN SCREEN
function renderLogin() {
  return `
    <div style="height:100%; padding:16px 20px; overflow-y:auto; background:#F8F8FD;">
      <div style="margin-bottom:16px;">
        <button onclick="loadScreen('walkthrough')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
      </div>

      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:20px;">
        <div>
          <h1 style="font-size:26px; font-weight:800; color:#191632;">Welcome<br>Back! 💜</h1>
          <p style="font-size:13px; color:#6B6984; margin-top:4px;">Log in to continue your journey.</p>
        </div>
        <div style="width:70px; height:70px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:32px;">
          🤗
        </div>
      </div>

      <div style="display:flex; background:#ECEBF7; border-radius:14px; padding:3px; margin-bottom:20px;">
        <button style="flex:1; padding:8px; background:#FFF; border:none; border-radius:12px; font-weight:700; color:#5E4BEE; font-size:13px; box-shadow:0 2px 6px rgba(0,0,0,0.05);">Log In</button>
        <button onclick="loadScreen('signup')" style="flex:1; padding:8px; background:transparent; border:none; font-weight:600; color:#6B6984; font-size:13px; cursor:pointer;">Create ID / Sign Up</button>
      </div>

      <div style="display:flex; flex-direction:column; gap:12px; margin-bottom:14px;">
        <input type="text" value="${currentUser.email}" placeholder="Email or ID" style="width:100%; padding:14px 18px; border-radius:16px; border:1px solid #ECEBF7; background:#FFF; font-size:14px;">
        <input type="password" value="••••••••" placeholder="Password" style="width:100%; padding:14px 18px; border-radius:16px; border:1px solid #ECEBF7; background:#FFF; font-size:14px;">
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; font-size:12px; margin-bottom:20px;">
        <label style="display:flex; align-items:center; gap:6px; color:#6B6984;">
          <input type="checkbox" checked style="accent-color:#5E4BEE;"> Remember me
        </label>
        <span style="color:#5E4BEE; font-weight:700; cursor:pointer;">Forgot Password?</span>
      </div>

      <button onclick="loadScreen('home')" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 6px 18px rgba(94,75,238,0.3);">
        Log In ➔
      </button>

      <div style="display:flex; align-items:center; gap:10px; margin: 20px 0;">
        <div style="flex:1; height:1px; background:#ECEBF7;"></div>
        <span style="font-size:11px; color:#9E9DB5;">or continue with</span>
        <div style="flex:1; height:1px; background:#ECEBF7;"></div>
      </div>

      <div style="display:flex; justify-content:center; gap:16px; margin-bottom:20px;">
        <div style="width:46px; height:46px; background:#FFF; border:1px solid #ECEBF7; border-radius:50%; display:flex; align-items:center; justify-content:center; font-weight:bold; color:#EA4335; cursor:pointer;">G</div>
        <div style="width:46px; height:46px; background:#FFF; border:1px solid #ECEBF7; border-radius:50%; display:flex; align-items:center; justify-content:center; font-weight:bold; color:#000; cursor:pointer;"></div>
        <div style="width:46px; height:46px; background:#FFF; border:1px solid #ECEBF7; border-radius:50%; display:flex; align-items:center; justify-content:center; font-weight:bold; color:#1877F2; cursor:pointer;">f</div>
      </div>

      <div style="padding:14px; background:#F3F1FD; border-radius:16px; display:flex; gap:10px; align-items:center;">
        <span style="font-size:22px;">🛡️</span>
        <div style="font-size:11px; color:#6B6984; line-height:1.3;">
          <strong style="color:#4534C7;">Your safety is our priority.</strong><br>
          We use end-to-end encryption to keep your emotional journey private.
        </div>
      </div>
    </div>
  `;
}

// 4. CREATE ID & SIGN UP SCREEN
function renderSignUp() {
  return `
    <div style="height:100%; padding:16px 20px; overflow-y:auto; background:#F8F8FD;">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
        <button onclick="loadScreen('login')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
        <span class="id-pill-chip">Step 1: Create ID</span>
      </div>

      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
        <div>
          <h1 style="font-size:24px; font-weight:800; color:#191632;">Create Your ID 🌱</h1>
          <p style="font-size:12px; color:#6B6984; margin-top:3px;">Your details will auto-sync across all screens.</p>
        </div>
        <div style="width:58px; height:58px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:28px;">
          🏷️
        </div>
      </div>

      <!-- Tab Switcher -->
      <div style="display:flex; background:#ECEBF7; border-radius:14px; padding:3px; margin-bottom:18px;">
        <button onclick="loadScreen('login')" style="flex:1; padding:8px; background:transparent; border:none; font-weight:600; color:#6B6984; font-size:12px; cursor:pointer;">Log In</button>
        <button style="flex:1; padding:8px; background:#FFF; border:none; border-radius:12px; font-weight:700; color:#5E4BEE; font-size:12px; box-shadow:0 2px 6px rgba(0,0,0,0.05);">Create ID / Sign Up</button>
      </div>

      <!-- ID Handle Input with Randomizer -->
      <div style="margin-bottom:14px;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
          <label style="font-size:11px; font-weight:700; color:#6B6984;">UNIQUE WEHERE ID / HANDLE</label>
          <span onclick="randomizeHandleInput()" style="font-size:11px; color:#5E4BEE; font-weight:bold; cursor:pointer;">🎲 Auto-Generate</span>
        </div>
        <div style="display:flex; gap:8px;">
          <div style="position:relative; flex:1;">
            <span style="position:absolute; left:14px; top:13px; font-size:14px; color:#5E4BEE; font-weight:bold;">@</span>
            <input id="signup-handle" type="text" value="${currentUser.id.replace('@', '')}" placeholder="your_unique_handle" style="width:100%; padding:12px 14px 12px 32px; border-radius:14px; border:1.5px solid #5E4BEE; background:#FFF; font-size:13px; font-weight:bold; color:#191632;">
          </div>
          <button onclick="randomizeHandleInput()" title="Generate Random Anonymous ID" style="padding:0 12px; background:#F0EEFF; border:1px solid #DDD6FE; border-radius:14px; font-size:11px; font-weight:700; color:#5E4BEE; cursor:pointer; display:flex; align-items:center; gap:4px;">
            🎲 Random
          </button>
        </div>
      </div>

      <!-- Full Name -->
      <div style="margin-bottom:12px;">
        <label style="font-size:11px; font-weight:700; color:#6B6984; margin-bottom:6px; display:block;">FULL NAME (OR PSEUDONYM)</label>
        <input id="signup-name" type="text" value="${currentUser.name}" placeholder="e.g. Alex Rivera" style="width:100%; padding:12px 14px; border-radius:14px; border:1px solid #ECEBF7; background:#FFF; font-size:13px;">
      </div>

      <!-- Email -->
      <div style="margin-bottom:14px;">
        <label style="font-size:11px; font-weight:700; color:#6B6984; margin-bottom:6px; display:block;">EMAIL ADDRESS</label>
        <input id="signup-email" type="email" value="${currentUser.email}" placeholder="alex@wehere.com" style="width:100%; padding:12px 14px; border-radius:14px; border:1px solid #ECEBF7; background:#FFF; font-size:13px;">
      </div>

      <!-- Primary Struggle Selection -->
      <div style="margin-bottom:16px;">
        <label style="font-size:11px; font-weight:700; color:#6B6984; margin-bottom:6px; display:block;">PRIMARY CHALLENGES (FOR AUTO-MATCHING)</label>
        <div style="display:flex; flex-wrap:wrap; gap:6px;">
          ${renderFeelingsToggle('Burnout', '🪫')}
          ${renderFeelingsToggle('Lonely', '😔')}
          ${renderFeelingsToggle('Anxious', '😟')}
          ${renderFeelingsToggle('Career Stress', '🎓')}
          ${renderFeelingsToggle('Self Growth', '🌱')}
        </div>
      </div>

      <!-- Live Auto-fetch preview card -->
      <div style="padding:12px; background:#F3F1FD; border:1px solid #DDD6FE; border-radius:14px; margin-bottom:18px; display:flex; gap:10px; align-items:center;">
        <span style="font-size:22px;">⚡</span>
        <div style="font-size:11px; color:#4534C7; line-height:1.35;">
          <strong>Auto-Fetch Ready:</strong> When you create this ID, your name, email, and emotional profile will automatically sync to your dashboard, matches, and intake wizard.
        </div>
      </div>

      <button onclick="handleCreateIdSubmit()" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 6px 18px rgba(94,75,238,0.35); display:flex; align-items:center; justify-content:center; gap:8px;">
        Create ID & Link Details ➔
      </button>

      <p style="text-align:center; font-size:12px; color:#6B6984; margin-top:14px;">
        Already registered? <span onclick="loadScreen('login')" style="color:#5E4BEE; font-weight:700; cursor:pointer;">Log In</span>
      </p>
    </div>
  `;
}

function renderFeelingsToggle(title, emoji) {
  const isSelected = currentUser.feelings.includes(title);
  return `
    <span class="chip-interactive ${isSelected ? 'selected' : ''}" onclick="toggleFeelingsSelection('${title}')">
      ${emoji} ${title}
    </span>
  `;
}

function toggleFeelingsSelection(feeling) {
  const idx = currentUser.feelings.indexOf(feeling);
  if (idx > -1) {
    currentUser.feelings.splice(idx, 1);
  } else {
    currentUser.feelings.push(feeling);
  }
  loadScreen('signup');
}

function randomizeHandleInput() {
  const handle = generateRandomHandle().replace('@', '');
  currentUser.id = '@' + handle;
  const el = document.getElementById('signup-handle');
  if (el) el.value = handle;
  showToast(`Auto-generated ID: @${handle}`);
}

function handleCreateIdSubmit() {
  const handleInput = document.getElementById('signup-handle');
  const nameInput = document.getElementById('signup-name');
  const emailInput = document.getElementById('signup-email');

  if (handleInput && handleInput.value.trim()) {
    currentUser.id = '@' + handleInput.value.trim().replace(/^@+/, '');
  }
  if (nameInput && nameInput.value.trim()) {
    currentUser.name = nameInput.value.trim();
  }
  if (emailInput && emailInput.value.trim()) {
    currentUser.email = emailInput.value.trim();
  }

  recalculateMatches();
  showToast(`ID Created: ${currentUser.id}! Details auto-fetched.`);
  loadScreen('otp');
}

// 5. OTP VERIFICATION
function renderOtp() {
  return `
    <div style="height:100%; padding:20px; display:flex; flex-direction:column; align-items:center; text-align:center; background:#F8F8FD;">
      <div style="align-self:flex-start;">
        <button onclick="loadScreen('signup')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
      </div>

      <div style="width:84px; height:84px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:38px; margin: 10px 0 16px 0; position:relative;">
        ✉️
        <span style="position:absolute; bottom:2px; right:2px; background:#22C55E; color:#FFF; font-size:12px; width:22px; height:22px; border-radius:50%; display:flex; align-items:center; justify-content:center;">✓</span>
      </div>

      <h2 style="font-size:22px; font-weight:800; color:#191632;">Verify Your Email</h2>
      <p style="font-size:12px; color:#6B6984; margin-top:4px;">We've sent a 6-digit code to</p>
      <p style="font-size:13px; font-weight:700; color:#5E4BEE; margin-bottom:8px;">${currentUser.email}</p>

      <!-- Linked ID Badge -->
      <div style="margin-bottom:18px;">
        <span class="id-pill-chip">🏷️ Linked ID: ${currentUser.id} • ${currentUser.name}</span>
      </div>

      <div style="display:flex; justify-content:center; gap:8px; margin-bottom:14px;">
        <input type="text" maxlength="1" value="7" style="width:42px; height:50px; text-align:center; font-size:20px; font-weight:bold; border-radius:12px; border:2px solid #5E4BEE; background:#FFF;">
        <input type="text" maxlength="1" value="4" style="width:42px; height:50px; text-align:center; font-size:20px; font-weight:bold; border-radius:12px; border:2px solid #5E4BEE; background:#FFF;">
        <input type="text" maxlength="1" value="2" style="width:42px; height:50px; text-align:center; font-size:20px; font-weight:bold; border-radius:12px; border:2px solid #5E4BEE; background:#FFF;">
        <input type="text" maxlength="1" value="9" style="width:42px; height:50px; text-align:center; font-size:20px; font-weight:bold; border-radius:12px; border:2px solid #5E4BEE; background:#FFF;">
        <input type="text" maxlength="1" value="1" style="width:42px; height:50px; text-align:center; font-size:20px; font-weight:bold; border-radius:12px; border:2px solid #5E4BEE; background:#FFF;">
        <input type="text" maxlength="1" value="0" style="width:42px; height:50px; text-align:center; font-size:20px; font-weight:bold; border-radius:12px; border:2px solid #5E4BEE; background:#FFF;">
      </div>

      <p style="font-size:11px; color:#9E9DB5; margin-bottom:18px;">Enter the 6-digit code above</p>

      <div style="padding:12px 14px; background:#F3F1FD; border-radius:14px; display:flex; gap:10px; align-items:center; text-align:left; width:100%; margin-bottom:18px;">
        <span style="font-size:18px;">🛡️</span>
        <div style="font-size:11px; color:#6B6984;">
          <strong>End-to-End Privacy:</strong> Your data is securely locked to ID <strong>${currentUser.id}</strong>.
        </div>
      </div>

      <p style="font-size:12px; color:#5E4BEE; font-weight:700; margin-bottom:20px;">Resend code in 00:45</p>

      <button onclick="handleOtpVerifySubmit()" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 6px 18px rgba(94,75,238,0.3);">
        Verify & Auto-Load Details ➔
      </button>
    </div>
  `;
}

function handleOtpVerifySubmit() {
  showToast(`✅ Code verified! Fetching data for ${currentUser.id}...`);
  currentOnboardingStep = 1;
  loadScreen('onboarding');
}

// 6. INTAKE & AUTO-FETCH FLOW (5 Steps)
function renderOnboarding() {
  return `
    <div style="height:100%; padding:16px 20px; overflow-y:auto; background:#F8F8FD; display:flex; flex-direction:column;">
      <!-- Header -->
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
        <button onclick="prevOnboardingStep()" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
        <div style="display:flex; align-items:center; gap:6px;">
          <span class="id-pill-chip">${currentUser.id}</span>
          <span style="font-size:12px; font-weight:700; color:#5E4BEE;">${currentOnboardingStep} / 5</span>
        </div>
      </div>

      <!-- Step Progress Bar (5 Steps) -->
      <div style="display:flex; gap:4px; margin-bottom:16px;">
        ${[1, 2, 3, 4, 5].map(step => `
          <div style="flex:1; height:4px; background:${step <= currentOnboardingStep ? '#5E4BEE' : '#ECEBF7'}; border-radius:2px; transition:all 0.2s;"></div>
        `).join('')}
      </div>

      <!-- Step Content -->
      <div style="flex:1; overflow-y:auto;">
        ${renderOnboardingStepContent()}
      </div>

      <!-- Bottom Navigation Button -->
      <div style="padding-top:14px;">
        <button onclick="nextOnboardingStep()" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 6px 18px rgba(94,75,238,0.3); display:flex; align-items:center; justify-content:center; gap:8px;">
          ${currentOnboardingStep === 5 ? 'Launch Experience 🚀' : 'Continue ➔'}
        </button>
      </div>
    </div>
  `;
}

function renderOnboardingStepContent() {
  switch (currentOnboardingStep) {
    case 1:
      return `
        <div>
          <div style="padding:10px 14px; background:#F0EEFF; border-radius:14px; margin-bottom:16px; display:flex; align-items:center; gap:8px;">
            <span>✨</span>
            <span style="font-size:11px; color:#4534C7; font-weight:600;">Details auto-fetched from your registered ID <strong>${currentUser.id}</strong></span>
          </div>

          <div style="text-align:center; margin-bottom:16px;">
            <span style="font-size:36px;">👤</span>
            <h2 style="font-size:20px; font-weight:800; color:#191632; margin-top:4px;">Tell us about yourself</h2>
            <p style="font-size:12px; color:#6B6984; margin-top:2px;">This helps personalize your peer connections.</p>
          </div>

          <div style="display:flex; flex-direction:column; gap:12px;">
            <div>
              <label style="font-size:11px; font-weight:700; color:#6B6984; margin-bottom:4px; display:block;">DISPLAY NAME</label>
              <input id="onboard-name" type="text" value="${currentUser.name}" onchange="currentUser.name = this.value" style="width:100%; padding:12px 14px; border-radius:14px; border:1px solid #ECEBF7; background:#FFF; font-size:13px;">
            </div>
            <div>
              <label style="font-size:11px; font-weight:700; color:#6B6984; margin-bottom:4px; display:block;">AGE</label>
              <input type="number" value="${currentUser.age}" onchange="currentUser.age = parseInt(this.value)" style="width:100%; padding:12px 14px; border-radius:14px; border:1px solid #ECEBF7; background:#FFF; font-size:13px;">
            </div>
            <div>
              <label style="font-size:11px; font-weight:700; color:#6B6984; margin-bottom:4px; display:block;">LOCATION</label>
              <input type="text" value="${currentUser.location}" onchange="currentUser.location = this.value" style="width:100%; padding:12px 14px; border-radius:14px; border:1px solid #ECEBF7; background:#FFF; font-size:13px;">
            </div>
          </div>
        </div>
      `;

    case 2:
      return `
        <div>
          <div style="text-align:center; margin-bottom:16px;">
            <span style="font-size:36px;">🎨</span>
            <h2 style="font-size:20px; font-weight:800; color:#191632; margin-top:4px;">Your Passions & Interests</h2>
            <p style="font-size:12px; color:#6B6984; margin-top:2px;">We'll match you with peers who share these.</p>
          </div>

          <div style="display:flex; flex-wrap:wrap; gap:8px;">
            ${['Reading', 'Nature', 'Music', 'Journaling', 'Mindfulness', 'Fitness', 'Art', 'Coffee', 'Personal Growth', 'Tech'].map(item => `
              <span class="chip-interactive ${currentUser.interests.includes(item) ? 'selected' : ''}" onclick="toggleInterestChip('${item}')">
                ${currentUser.interests.includes(item) ? '✓' : '+'} ${item}
              </span>
            `).join('')}
          </div>
        </div>
      `;

    case 3:
      return `
        <div>
          <div style="text-align:center; margin-bottom:16px;">
            <span style="font-size:36px;">🌧️</span>
            <h2 style="font-size:20px; font-weight:800; color:#191632; margin-top:4px;">How are you feeling lately?</h2>
            <p style="font-size:12px; color:#6B6984; margin-top:2px;">Select all that relate to your current headspace.</p>
          </div>

          <div style="display:grid; grid-template-columns:repeat(3, 1fr); gap:10px;">
            ${[
              { name: 'Burnout', emoji: '🪫' },
              { name: 'Lonely', emoji: '😔' },
              { name: 'Anxious', emoji: '😟' },
              { name: 'Stressed', emoji: '😫' },
              { name: 'Heartbroken', emoji: '💔' },
              { name: 'Career Pressure', emoji: '🎓' },
              { name: 'Family Issues', emoji: '👥' },
              { name: 'Overwhelmed', emoji: '🌧️' },
              { name: 'Self Growth', emoji: '🌱' }
            ].map(f => `
              <div onclick="toggleFeelingChip('${f.name}')" style="background:${currentUser.feelings.includes(f.name) ? '#F0EEFF' : '#FFF'}; border:1.5px solid ${currentUser.feelings.includes(f.name) ? '#5E4BEE' : '#ECEBF7'}; border-radius:16px; padding:12px 6px; text-align:center; cursor:pointer;">
                <div style="font-size:24px; margin-bottom:4px;">${f.emoji}</div>
                <div style="font-size:11px; font-weight:700; color:${currentUser.feelings.includes(f.name) ? '#5E4BEE' : '#191632'};">${f.name}</div>
              </div>
            `).join('')}
          </div>
        </div>
      `;

    case 4:
      return `
        <div>
          <div style="text-align:center; margin-bottom:16px;">
            <span style="font-size:36px;">🤝</span>
            <h2 style="font-size:20px; font-weight:800; color:#191632; margin-top:4px;">What are you looking for?</h2>
            <p style="font-size:12px; color:#6B6984; margin-top:2px;">Help matches understand your intentions.</p>
          </div>

          <div style="display:flex; flex-direction:column; gap:10px;">
            ${[
              { title: 'Someone to Talk To', desc: 'A compassionate friend to chat with casually' },
              { title: 'Emotional Support', desc: 'Mutual empathy during heavy moments' },
              { title: 'Accountability Partner', desc: 'Encouraging daily routines & wellness habits' },
              { title: 'Deep Conversations', desc: 'Meaningful philosophy, life reflections & healing' }
            ].map(item => `
              <div onclick="toggleLookingForChip('${item.title}')" style="padding:14px; background:${currentUser.lookingFor.includes(item.title) ? '#F0EEFF' : '#FFF'}; border:1.5px solid ${currentUser.lookingFor.includes(item.title) ? '#5E4BEE' : '#ECEBF7'}; border-radius:16px; cursor:pointer; display:flex; justify-content:space-between; align-items:center;">
                <div>
                  <h4 style="font-size:13px; font-weight:700; color:#191632;">${item.title}</h4>
                  <p style="font-size:11px; color:#6B6984; margin-top:2px;">${item.desc}</p>
                </div>
                <div style="width:20px; height:20px; border-radius:50%; border:2px solid ${currentUser.lookingFor.includes(item.title) ? '#5E4BEE' : '#ECEBF7'}; background:${currentUser.lookingFor.includes(item.title) ? '#5E4BEE' : 'transparent'}; display:flex; align-items:center; justify-content:center; color:#FFF; font-size:11px;">
                  ${currentUser.lookingFor.includes(item.title) ? '✓' : ''}
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `;

    case 5:
      return `
        <div>
          <div style="text-align:center; margin-bottom:14px;">
            <span style="font-size:36px;">✨</span>
            <h2 style="font-size:20px; font-weight:800; color:#191632; margin-top:4px;">All Set & Linked!</h2>
            <p style="font-size:12px; color:#6B6984; margin-top:2px;">Review your auto-fetched details before entering.</p>
          </div>

          <!-- Summary Card -->
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:20px; padding:16px; margin-bottom:14px; box-shadow:0 4px 12px rgba(0,0,0,0.03);">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
              <span class="id-pill-chip">ID: ${currentUser.id}</span>
              <span style="font-size:11px; color:#22C55E; font-weight:bold;">🟢 Ready to Connect</span>
            </div>
            <div style="font-size:16px; font-weight:800; color:#191632;">${currentUser.name}, ${currentUser.age}</div>
            <div style="font-size:12px; color:#6B6984; margin:2px 0 10px 0;">${currentUser.location} • ${currentUser.email}</div>

            <div style="font-size:11px; font-weight:bold; color:#191632; margin-bottom:6px;">Current Headspace:</div>
            <div style="display:flex; flex-wrap:wrap; gap:4px; margin-bottom:10px;">
              ${currentUser.feelings.map(f => `<span style="background:#F0EEFF; color:#5E4BEE; padding:3px 8px; border-radius:10px; font-size:10px; font-weight:bold;">${f}</span>`).join('')}
            </div>

            <div style="font-size:11px; font-weight:bold; color:#191632; margin-bottom:6px;">Interests:</div>
            <div style="display:flex; flex-wrap:wrap; gap:4px;">
              ${currentUser.interests.map(i => `<span style="background:#F3F3FA; color:#191632; padding:3px 8px; border-radius:10px; font-size:10px;">${i}</span>`).join('')}
            </div>
          </div>

          <!-- Anonymity Toggle -->
          <div style="padding:14px; background:#FFF; border:1.5px solid ${currentUser.isAnonymous ? '#5E4BEE' : '#ECEBF7'}; border-radius:18px; display:flex; align-items:center; justify-content:space-between; margin-bottom:14px;">
            <div style="display:flex; align-items:center; gap:10px;">
              <div style="width:38px; height:38px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px;">🎭</div>
              <div>
                <h4 style="font-size:13px; font-weight:700; color:#191632;">Anonymity Mode</h4>
                <p style="font-size:11px; color:#6B6984;">Show safe avatar & alias to peers</p>
              </div>
            </div>
            <input type="checkbox" ${currentUser.isAnonymous ? 'checked' : ''} onchange="currentUser.isAnonymous = this.checked; userAnonymous = this.checked;" style="width:20px; height:20px; accent-color:#5E4BEE; cursor:pointer;">
          </div>
        </div>
      `;

    default:
      return '';
  }
}

function nextOnboardingStep() {
  if (currentOnboardingStep < 5) {
    currentOnboardingStep++;
    loadScreen('onboarding');
  } else {
    completeOnboardingFlow();
  }
}

function prevOnboardingStep() {
  if (currentOnboardingStep > 1) {
    currentOnboardingStep--;
    loadScreen('onboarding');
  } else {
    loadScreen('otp');
  }
}

function toggleInterestChip(interest) {
  const idx = currentUser.interests.indexOf(interest);
  if (idx > -1) {
    currentUser.interests.splice(idx, 1);
  } else {
    currentUser.interests.push(interest);
  }
  loadScreen('onboarding');
}

function toggleFeelingChip(feeling) {
  const idx = currentUser.feelings.indexOf(feeling);
  if (idx > -1) {
    currentUser.feelings.splice(idx, 1);
  } else {
    currentUser.feelings.push(feeling);
  }
  loadScreen('onboarding');
}

function toggleLookingForChip(val) {
  const idx = currentUser.lookingFor.indexOf(val);
  if (idx > -1) {
    currentUser.lookingFor.splice(idx, 1);
  } else {
    currentUser.lookingFor.push(val);
  }
  loadScreen('onboarding');
}

function completeOnboardingFlow() {
  recalculateMatches();
  showToast(`Welcome, ${currentUser.name}! Dynamic matches loaded for ${currentUser.id}.`);
  loadScreen('home');
}

// 7. HOME DASHBOARD
function renderHome() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD;">
      <!-- Scrollable body -->
      <div style="flex:1; overflow-y:auto; padding:14px 18px;">
        <!-- Top App Bar Header -->
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
          <!-- Avatar tapping to profile -->
          <div onclick="loadScreen('profile')" style="display:flex; align-items:center; gap:8px; cursor:pointer;" title="View Profile">
            <div style="position:relative;">
              <img src="${currentUser.avatarUrl}" style="width:40px; height:40px; border-radius:50%; object-fit:cover; border:1.5px solid #5E4BEE;">
              <span style="position:absolute; bottom:0; right:0; width:10px; height:10px; background:#22C55E; border:2px solid #FFF; border-radius:50%;"></span>
            </div>
            <div>
              <div style="display:flex; align-items:center; gap:4px;">
                <h3 style="font-size:15px; font-weight:800; color:#191632;">Hi, ${currentUser.isAnonymous ? 'Friend' : currentUser.name.split(' ')[0]} 👋</h3>
              </div>
              <span class="id-pill-chip" style="font-size:9px; padding:1px 6px;">${currentUser.id}</span>
            </div>
          </div>

          <!-- SOS Emergency Help & Notification Icon -->
          <div style="display:flex; align-items:center; gap:8px;">
            <button class="sos-header-pill" onclick="loadScreen('sos')">
              🚨 SOS
            </button>
            <div style="width:36px; height:36px; background:#FFF; border:1px solid #ECEBF7; border-radius:50%; display:flex; align-items:center; justify-content:center; position:relative; cursor:pointer;" onclick="showSimulatorNotifications()">
              🔔
              <span style="position:absolute; top:4px; right:4px; width:7px; height:7px; background:#5E4BEE; border-radius:50%;"></span>
            </div>
          </div>
        </div>

        <!-- Hero Card -->
        <div style="padding:16px; background:#F0EDFD; border:1px solid rgba(94,75,238,0.2); border-radius:22px; display:flex; align-items:center; justify-content:space-between; margin-bottom:18px;">
          <div>
            <h4 style="font-size:15px; font-weight:800; color:#191632;">You're not alone. 💜</h4>
            <p style="font-size:11px; color:#6B6984; margin:3px 0 10px 0; max-width:180px;">Matches dynamically calculated for <strong>${currentUser.id}</strong>.</p>
            <button onclick="loadScreen('discover')" style="padding:8px 14px; background:#5E4BEE; color:#FFF; border:none; border-radius:18px; font-size:11px; font-weight:700; cursor:pointer; box-shadow:0 4px 12px rgba(94,75,238,0.3);">
              Find Someone to Talk To ➔
            </button>
          </div>
          <div style="font-size:52px;">🧘‍♀️</div>
        </div>

        <!-- Quick Action 5 Circles -->
        <div style="display:flex; justify-content:space-between; text-align:center; margin-bottom:18px;">
          <div onclick="loadScreen('chat')" style="cursor:pointer;">
            <div style="width:48px; height:48px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:20px; margin:0 auto 4px auto; position:relative;">
              💬
              <span style="position:absolute; top:0; right:0; background:#EF4444; color:#FFF; font-size:9px; font-weight:bold; border-radius:50%; width:16px; height:16px; display:flex; align-items:center; justify-content:center;">2</span>
            </div>
            <span style="font-size:10px; font-weight:700; color:#191632;">Chat</span>
          </div>

          <div onclick="loadScreen('discover')" style="cursor:pointer;">
            <div style="width:48px; height:48px; background:#E7F9EE; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:20px; margin:0 auto 4px auto;">🧭</div>
            <span style="font-size:10px; font-weight:700; color:#191632;">Discover</span>
          </div>

          <div onclick="loadScreen('community')" style="cursor:pointer;">
            <div style="width:48px; height:48px; background:#FFF3E0; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:20px; margin:0 auto 4px auto;">⭕</div>
            <span style="font-size:10px; font-weight:700; color:#191632;">Circles</span>
          </div>

          <div onclick="loadScreen('journal_new')" style="cursor:pointer;">
            <div style="width:48px; height:48px; background:#FCE4EC; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:20px; margin:0 auto 4px auto;">💖</div>
            <span style="font-size:10px; font-weight:700; color:#191632;">Check-in</span>
          </div>

          <div onclick="loadScreen('sos')" style="cursor:pointer;">
            <div style="width:48px; height:48px; background:#FDE8E8; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:20px; margin:0 auto 4px auto;">🚨</div>
            <span style="font-size:10px; font-weight:700; color:#EF4444;">SOS Help</span>
          </div>
        </div>

        <!-- Progress Card (Streak) -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:20px; padding:14px; margin-bottom:18px;">
          <div style="display:flex; justify-content:space-between; margin-bottom:10px;">
            <span style="font-size:13px; font-weight:800; color:#191632;">Your Progress</span>
            <span onclick="loadScreen('progress')" style="font-size:11px; font-weight:700; color:#5E4BEE; cursor:pointer;">View all ➔</span>
          </div>
          <div style="display:flex; gap:10px; margin-bottom:12px;">
            <div style="flex:1; background:#F3F3FA; border-radius:14px; padding:10px; display:flex; align-items:center; gap:8px;">
              <span style="font-size:20px;">🔥</span>
              <div>
                <strong style="font-size:15px; color:#191632;">${currentUser.streakDays}</strong>
                <p style="font-size:9px; color:#6B6984;">Days in a row</p>
              </div>
            </div>
            <div style="flex:1; background:#F3F3FA; border-radius:14px; padding:10px; display:flex; align-items:center; gap:8px;">
              <span style="font-size:20px;">👥</span>
              <div>
                <strong style="font-size:15px; color:#191632;">3</strong>
                <p style="font-size:9px; color:#6B6984;">People connected</p>
              </div>
            </div>
          </div>
          <div style="font-size:11px; font-weight:600; color:#191632; margin-bottom:4px;">Keep it up! You're doing great. 🌱</div>
          <div style="width:100%; height:6px; background:#ECEBF7; border-radius:3px; overflow:hidden;">
            <div style="width:85%; height:100%; background:#5E4BEE;"></div>
          </div>
        </div>

        <!-- Daily Mood Picker -->
        <div style="margin-bottom:18px;">
          <div style="display:flex; justify-content:space-between; margin-bottom:10px;">
            <span style="font-size:13px; font-weight:800; color:#191632;">How are you feeling today?</span>
            <span onclick="loadScreen('journal_new')" style="font-size:11px; font-weight:700; color:#5E4BEE; cursor:pointer;">Daily Check-in ➔</span>
          </div>
          <div style="display:flex; justify-content:space-between;">
            ${renderSmallMood('Great', '😄', '#22C55E', true)}
            ${renderSmallMood('Good', '🙂', '#3B82F6', false)}
            ${renderSmallMood('Okay', '😐', '#F59E0B', false)}
            ${renderSmallMood('Not Good', '🙁', '#F97316', false)}
            ${renderSmallMood('Struggling', '😣', '#EF4444', false)}
          </div>
        </div>

        <!-- Recommended Peers with Live Match % -->
        <div>
          <div style="display:flex; justify-content:space-between; margin-bottom:10px;">
            <span style="font-size:13px; font-weight:800; color:#191632;">Recommended For You</span>
            <span onclick="loadScreen('discover')" style="font-size:11px; font-weight:700; color:#5E4BEE; cursor:pointer;">View all ➔</span>
          </div>
          <div style="display:flex; gap:10px; overflow-x:auto; padding-bottom:6px;">
            ${cardsData.map(c => `
              <div style="min-width:130px; background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:10px; text-align:center; flex-shrink:0;">
                <img src="${c.img}" style="width:50px; height:50px; border-radius:50%; object-fit:cover; margin:0 auto 6px auto; display:block;">
                <strong style="font-size:12px; color:#191632; display:block;">${c.name.split(',')[0]}</strong>
                <span style="font-size:9px; font-weight:bold; color:#5E4BEE; background:#F0EEFF; padding:2px 6px; border-radius:8px; display:inline-block; margin:2px 0;">💜 ${c.matchPct}% Match</span>
                <p style="font-size:9px; color:#6B6984; height:22px; overflow:hidden; margin:2px 0 6px 0;">${c.lookingFor.slice(0, 26)}...</p>
                <button onclick="loadScreen('discover')" style="width:100%; padding:4px; background:#5E4BEE; color:#FFF; border:none; border-radius:12px; font-size:10px; font-weight:bold; cursor:pointer;">Connect</button>
              </div>
            `).join('')}
          </div>
        </div>
      </div>

      <!-- Clean 5-Tab Bottom Navigation -->
      ${renderBottomNav('home')}
    </div>
  `;
}

function renderSmallMood(label, emoji, color, selected) {
  return `
    <div onclick="loadScreen('journal_new')" style="background:${selected ? '#F0EEFF' : '#FFF'}; border:1px solid ${selected ? color : '#ECEBF7'}; border-radius:14px; padding:8px 6px; text-align:center; width:58px; cursor:pointer;">
      <div style="font-size:20px;">${emoji}</div>
      <div style="font-size:9px; font-weight:700; color:${selected ? color : '#191632'}; margin-top:2px;">${label}</div>
    </div>
  `;
}

// 8. TINDER SWIPE DECK
function renderDiscover() {
  const card = cardsData[swipeCardIndex % cardsData.length];
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD; position:relative;">
      <!-- Header with SOS Pill -->
      <div style="padding:10px 18px; display:flex; justify-content:space-between; align-items:center;">
        <div style="width:36px; height:36px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px;">🤝</div>
        <div style="text-align:center;">
          <h3 style="font-size:16px; font-weight:800; color:#191632;">Find Your People ✨</h3>
          <p style="font-size:10px; color:#6B6984;">Compatibility tailored to <strong>${currentUser.id}</strong></p>
        </div>
        <div style="display:flex; align-items:center; gap:6px;">
          <button class="sos-header-pill" onclick="loadScreen('sos')">
            🚨 SOS
          </button>
          <button onclick="showDeckFiltersModal()" style="width:34px; height:34px; border-radius:50%; border:1px solid #ECEBF7; background:#FFF; display:flex; align-items:center; justify-content:center; cursor:pointer; font-size:16px; box-shadow:0 2px 6px rgba(0,0,0,0.05);" title="Discover Filters (☲)">
            ☲
          </button>
        </div>
      </div>

      <!-- Filter Tabs -->
      <div style="display:flex; gap:8px; padding:0 18px 8px 18px; overflow-x:auto;">
        <span style="padding:5px 14px; background:#5E4BEE; color:#FFF; border-radius:16px; font-size:11px; font-weight:700;">For You</span>
        <span style="padding:5px 14px; background:#FFF; border:1px solid #ECEBF7; color:#6B6984; border-radius:16px; font-size:11px; font-weight:600;">New</span>
        <span style="padding:5px 14px; background:#FFF; border:1px solid #ECEBF7; color:#6B6984; border-radius:16px; font-size:11px; font-weight:600;">Active Now 🟢</span>
      </div>

      <!-- Card Container with Touch/Drag -->
      <div style="flex:1; padding:6px 14px; position:relative; display:flex; align-items:center; justify-content:center;">
        <!-- Stack Depth Indicator -->
        <div style="position:absolute; width:90%; height:94%; background:#FFF; border-radius:26px; border:1px solid #ECEBF7; opacity:0.6; transform:translateY(6px);"></div>

        <!-- Active Swipeable Card -->
        <div id="swipe-card" class="swipe-card" style="width:100%; height:100%; border-radius:26px; overflow:hidden; position:relative; box-shadow:0 12px 30px rgba(0,0,0,0.15); cursor:grab; touch-action:none;">
          <img src="${card.img}" style="width:100%; height:100%; object-fit:cover;">

          <!-- Overlay Scrim -->
          <div style="position:absolute; inset:0; background:linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.4) 50%, rgba(0,0,0,0.88) 100%);"></div>

          <!-- CONNECT / PASS stamps -->
          <div id="stamp-like" style="position:absolute; top:24px; left:20px; border:3px solid #5E4BEE; color:#5E4BEE; background:rgba(255,255,255,0.9); padding:4px 12px; border-radius:10px; font-size:18px; font-weight:900; transform:rotate(-15deg); opacity:0; pointer-events:none;">CONNECT</div>
          <div id="stamp-pass" style="position:absolute; top:24px; right:20px; border:3px solid #EF4444; color:#EF4444; background:rgba(255,255,255,0.9); padding:4px 12px; border-radius:10px; font-size:18px; font-weight:900; transform:rotate(15deg); opacity:0; pointer-events:none;">PASS</div>

          <!-- Top Badge -->
          <div style="position:absolute; top:16px; left:16px; background:rgba(255,255,255,0.9); padding:4px 10px; border-radius:16px; font-size:11px; font-weight:bold; color:#191632;">
            ✨ Verified Peer
          </div>

          <!-- Card Details -->
          <div style="position:absolute; bottom:14px; left:14px; right:14px; color:#FFF;">
            <div style="display:flex; align-items:center; gap:6px;">
              <h2 style="font-size:22px; font-weight:800;">${card.name}</h2>
              <span style="background:#8B7CF8; color:#FFF; font-size:11px; width:16px; height:16px; border-radius:50%; display:inline-flex; align-items:center; justify-content:center;">✓</span>
            </div>
            <div style="font-size:11px; color:#E0E7FF; margin:2px 0 4px 0;">${card.mood} • 🟢 Online</div>
            <p style="font-size:11px; color:rgba(255,255,255,0.85); line-height:1.3; margin-bottom:8px;">${card.bio}</p>

            <!-- Compatibility Reason Box -->
            <div style="background:rgba(0,0,0,0.5); backdrop-filter:blur(6px); border:1px solid rgba(139,124,248,0.4); border-radius:12px; padding:6px 10px; margin-bottom:8px; font-size:10px; color:#EDE9FE;">
              💡 <strong>Match Insight:</strong> ${card.compatibilityReason}
            </div>

            <div style="text-align:center;">
              <span style="background:rgba(0,0,0,0.7); border:1px solid rgba(94,75,238,0.6); padding:4px 14px; border-radius:14px; font-size:11px; font-weight:700;">
                💜 ${card.matchPct}% Match
              </span>
            </div>
          </div>
        </div>
      </div>

      <div style="text-align:center; font-size:11px; color:#6B6984; padding:2px 0;">
        Swipe <strong style="color:#5E4BEE;">right</strong> to connect • Swipe <strong style="color:#EF4444;">left</strong> to pass
      </div>

      <!-- Floating Action Buttons -->
      <div style="display:flex; justify-content:center; align-items:center; gap:20px; padding:6px 0 10px 0;">
        <button onclick="triggerSwipe('left')" style="width:52px; height:52px; border-radius:50%; background:#FFF; border:1px solid #ECEBF7; font-size:18px; color:#8E8EA9; cursor:pointer; box-shadow:0 6px 16px rgba(0,0,0,0.06);">✕</button>
        <button onclick="triggerSwipe('right')" style="width:64px; height:64px; border-radius:50%; background:#5E4BEE; border:none; font-size:26px; color:#FFF; cursor:pointer; box-shadow:0 8px 24px rgba(94,75,238,0.45);">💜</button>
        <button onclick="triggerSwipe('right')" style="width:52px; height:52px; border-radius:50%; background:#FFF; border:1px solid #ECEBF7; font-size:20px; color:#FF4081; cursor:pointer; box-shadow:0 6px 16px rgba(0,0,0,0.06);">⭐</button>
      </div>

      ${renderBottomNav('discover')}
    </div>
  `;
}

function initSwipePhysics() {
  const card = document.getElementById('swipe-card');
  const stampLike = document.getElementById('stamp-like');
  const stampPass = document.getElementById('stamp-pass');
  if (!card) return;

  let isDragging = false;
  let startX = 0;
  let currentX = 0;

  function onStart(e) {
    isDragging = true;
    startX = e.type.includes('touch') ? e.touches[0].clientX : e.clientX;
    card.style.transition = 'none';
  }

  function onMove(e) {
    if (!isDragging) return;
    const clientX = e.type.includes('touch') ? e.touches[0].clientX : e.clientX;
    currentX = clientX - startX;
    const rotation = currentX * 0.08;
    card.style.transform = `translateX(${currentX}px) rotate(${rotation}deg)`;

    if (currentX > 30) {
      stampLike.style.opacity = Math.min(currentX / 100, 1);
      stampPass.style.opacity = 0;
    } else if (currentX < -30) {
      stampPass.style.opacity = Math.min(-currentX / 100, 1);
      stampLike.style.opacity = 0;
    } else {
      stampLike.style.opacity = 0;
      stampPass.style.opacity = 0;
    }
  }

  function onEnd() {
    if (!isDragging) return;
    isDragging = false;
    card.style.transition = 'transform 0.3s ease';

    if (currentX > 100) {
      triggerSwipe('right');
    } else if (currentX < -100) {
      triggerSwipe('left');
    } else {
      card.style.transform = 'translateX(0) rotate(0)';
      stampLike.style.opacity = 0;
      stampPass.style.opacity = 0;
    }
  }

  card.addEventListener('mousedown', onStart);
  window.addEventListener('mousemove', onMove);
  window.addEventListener('mouseup', onEnd);

  card.addEventListener('touchstart', onStart);
  window.addEventListener('touchmove', onMove);
  window.addEventListener('touchend', onEnd);
}

function triggerSwipe(dir) {
  const card = document.getElementById('swipe-card');
  if (!card) return;

  card.style.transition = 'transform 0.4s ease, opacity 0.4s ease';
  if (dir === 'right') {
    card.style.transform = 'translateX(400px) rotate(30deg)';
    card.style.opacity = '0';
    setTimeout(() => {
      loadScreen('match_modal');
    }, 300);
  } else {
    card.style.transform = 'translateX(-400px) rotate(-30deg)';
    card.style.opacity = '0';
    setTimeout(() => {
      swipeCardIndex++;
      loadScreen('discover');
    }, 300);
  }
}

// 8. CELEBRATION "IT'S A MATCH!" (Mockup 1.17.18 AM)
function renderMatchCelebration() {
  return `
    <div style="height:100%; background:#0C0A1E; color:#FFF; padding:20px; overflow-y:auto; display:flex; flex-direction:column; justify-content:space-between;">
      <div style="display:flex; justify-content:flex-end;">
        <button onclick="loadScreen('discover')" style="background:rgba(255,255,255,0.12); border:none; color:#FFF; padding:6px 14px; border-radius:20px; font-size:12px; font-weight:700; cursor:pointer;">✕ Close</button>
      </div>

      <div style="text-align:center; margin:10px 0;">
        <h1 style="font-family:serif; font-size:36px; font-weight:bold; letter-spacing:0.5px;">It's a Match! 💜</h1>
        <p style="font-size:13px; color:rgba(255,255,255,0.7); margin-top:4px;">
          You and Riya liked each other.<br>Let's start a meaningful conversation!
        </p>
      </div>

      <!-- Side by Side Glowing Cards -->
      <div style="display:flex; justify-content:center; align-items:center; margin:16px 0;">
        <div style="width:115px; height:140px; border-radius:20px; overflow:hidden; border:2px solid #8B7CF8; box-shadow:0 0 20px rgba(94,75,238,0.5);">
          <img src="../assets/mockups/user_dashboard_alex.jpeg" style="width:100%; height:100%; object-fit:cover;">
        </div>

        <div style="width:38px; height:38px; background:#5E4BEE; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px; margin:0 -12px; z-index:10; box-shadow:0 0 16px #A855F7;">
          ♥
        </div>

        <div style="width:115px; height:140px; border-radius:20px; overflow:hidden; border:2px solid #8B7CF8; box-shadow:0 0 20px rgba(94,75,238,0.5);">
          <img src="../assets/mockups/discover_swipe.jpeg" style="width:100%; height:100%; object-fit:cover;">
        </div>
      </div>

      <!-- Shared Connection Card -->
      <div style="background:#161234; border:1px solid rgba(255,255,255,0.08); border-radius:20px; padding:14px; text-align:center; margin-bottom:16px;">
        <div style="font-size:13px; font-weight:bold; margin-bottom:8px;">💜 You both connect on</div>
        <div style="display:flex; justify-content:center; gap:6px; flex-wrap:wrap; margin-bottom:8px;">
          <span style="background:rgba(99,102,241,0.25); border:1px solid rgba(99,102,241,0.5); padding:4px 8px; border-radius:12px; font-size:10px;">🌿 Healing & Growing</span>
          <span style="background:rgba(139,92,246,0.25); border:1px solid rgba(139,92,246,0.5); padding:4px 8px; border-radius:12px; font-size:10px;">📖 Reading</span>
          <span style="background:rgba(16,185,129,0.25); border:1px solid rgba(16,185,129,0.5); padding:4px 8px; border-radius:12px; font-size:10px;">🍃 Nature</span>
        </div>
        <p style="font-size:11px; color:rgba(255,255,255,0.6); line-height:1.3;">
          You both believe in kindness, personal growth and being a better version of yourself. 🌱
        </p>
      </div>

      <!-- CTAs -->
      <div style="display:flex; flex-direction:column; gap:10px;">
        <button onclick="loadScreen('chat')" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 6px 18px rgba(94,75,238,0.4);">
          💬 Start Chatting ➔
        </button>
        <button onclick="loadScreen('chat')" style="width:100%; height:50px; background:#1B163B; color:#FFF; border:1px solid rgba(255,255,255,0.1); border-radius:25px; font-size:12px; font-weight:600; cursor:pointer;">
          ✨ Send a Gentle Icebreaker ➔
        </button>
        <div onclick="loadScreen('discover')" style="text-align:center; font-size:12px; color:#8B7CF8; font-weight:600; cursor:pointer; padding:6px;">
          Keep Swiping 🔄
        </div>
      </div>
    </div>
  `;
}

// 9. CHAT SCREEN (Mockup 1.17.17 AM (1))
function renderChat() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD;">
      <!-- Header -->
      <div style="padding:10px 14px; background:#FFF; border-bottom:1px solid #ECEBF7; display:flex; align-items:center; justify-content:space-between;">
        <div style="display:flex; align-items:center; gap:8px;">
          <button onclick="loadScreen('home')" style="background:none; border:none; font-size:16px; color:#5E4BEE; cursor:pointer;">❮</button>
          <div style="position:relative;">
            <img src="../assets/mockups/discover_swipe.jpeg" style="width:38px; height:38px; border-radius:50%; object-fit:cover;">
            <span style="position:absolute; bottom:0; right:0; width:10px; height:10px; background:#22C55E; border:2px solid #FFF; border-radius:50%;"></span>
          </div>
          <div>
            <div style="display:flex; align-items:center; gap:4px;">
              <strong style="font-size:14px; color:#191632;">Riya</strong>
              <span style="color:#5E4BEE; font-size:12px;">✓</span>
            </div>
            <div style="font-size:10px; color:#5E4BEE; font-weight:600;">Online • Healing & Growing 💜</div>
          </div>
        </div>
        <div style="display:flex; gap:8px;">
          <button onclick="showWeherePlusSubscriptionModal()" style="width:34px; height:34px; background:#F0EEFF; border:none; border-radius:50%; color:#5E4BEE; cursor:pointer;" title="Wehere Plus Voice Calling">📞</button>
          <button onclick="showSimulatorSafetyModal()" style="width:34px; height:34px; background:none; border:none; font-size:16px; cursor:pointer;" title="Safety & Options">⋮</button>
        </div>
      </div>

      <!-- Safe Space Banner -->
      <div style="padding:10px 14px; background:#F4F1FD; border-bottom:1px solid #DDD6FE; display:flex; align-items:center; gap:10px;">
        <span style="font-size:20px;">🛡️</span>
        <div style="flex:1; font-size:10px; color:#4534C7; line-height:1.3;">
          <strong>You're in a Safe Space</strong><br>
          Be kind, respectful and supportive. We're here for positive connection.
        </div>
      </div>

      <!-- Chat Bubble Feed -->
      <div id="chat-feed" style="flex:1; overflow-y:auto; padding:12px 14px; display:flex; flex-direction:column; gap:10px;">
        <div style="text-align:center;"><span style="font-size:10px; color:#9E9DB5; background:#ECEBF7; padding:2px 8px; border-radius:10px;">Today</span></div>
        ${renderIncomingMsg('Hey! 😊 How was your day?', '10:32 AM')}
        ${renderOutgoingMsg('Hey Riya! It was okay. A bit tiring but productive.', '10:35 AM')}
        ${renderIncomingMsg('That\'s great! ✨ What\'s one good thing that happened today?', '10:36 AM')}
        ${renderOutgoingMsg('I finally finished a task I was procrastinating on 😅 Feeling proud!', '10:37 AM')}
        ${renderIncomingMsg('Yay! Small wins matter a lot 💜 Celebrate them always!', '10:38 AM')}
        ${renderOutgoingMsg('True that! Also, talking to you always makes me feel a bit lighter. Thanks for being here! 😊', '10:39 AM')}
        ${renderIncomingMsg('Aww, that means a lot 🥺 I\'m glad we connected. I\'m here whenever you need to talk 🤗', '10:40 AM')}
        ${renderOutgoingMsg('Thank you, Riya! 💜', '10:41 AM')}
      </div>

      <!-- Daily Wellness Tip Bar -->
      <div style="padding:8px 14px; background:#E8F7F0; border-top:1px solid #C7EED8; font-size:11px; color:#1E6E45; display:flex; justify-content:space-between; align-items:center;">
        <span>🌿 <strong>Tip:</strong> Take breaks, breathe, and be gentle with yourself.</span>
        <span style="cursor:pointer;" onclick="this.parentElement.style.display='none'">✕</span>
      </div>

      <!-- Message Input Bar -->
      <div style="padding:8px 12px; background:#FFF; border-top:1px solid #ECEBF7; display:flex; align-items:center; gap:8px;">
        <button onclick="sendIcebreakerQuickPrompt('What made you smile today? ✨')" style="width:36px; height:36px; background:#F0EEFF; border:none; border-radius:50%; color:#5E4BEE; font-size:18px; cursor:pointer;" title="Send Wellness Icebreaker">+</button>
        <input id="chat-input" type="text" placeholder="Type a message..." onkeydown="if(event.key==='Enter') sendLiveMessage()" style="flex:1; padding:10px 14px; border-radius:20px; border:1px solid #ECEBF7; background:#F3F3FA; font-size:13px;">
        <button onclick="sendLiveMessage()" style="width:38px; height:38px; background:#5E4BEE; border:none; border-radius:50%; color:#FFF; cursor:pointer;">➔</button>
      </div>
    </div>
  `;
}

function renderIncomingMsg(text, time) {
  return `
    <div style="display:flex; gap:8px; max-width:80%;">
      <img src="../assets/mockups/discover_swipe.jpeg" style="width:26px; height:26px; border-radius:50%; object-fit:cover;">
      <div>
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:4px 16px 16px 16px; padding:10px 12px; font-size:12px; color:#191632; box-shadow:0 2px 4px rgba(0,0,0,0.02);">${text}</div>
        <span style="font-size:9px; color:#9E9DB5; margin-left:4px;">${time}</span>
      </div>
    </div>
  `;
}

function renderOutgoingMsg(text, time) {
  return `
    <div style="align-self:flex-end; max-width:80%; text-align:right;">
      <div style="background:#EEEAFE; border-radius:16px 16px 4px 16px; padding:10px 12px; font-size:12px; color:#191632; text-align:left;">${text}</div>
      <span style="font-size:9px; color:#9E9DB5; margin-right:4px;">${time} ✓✓</span>
    </div>
  `;
}

function sendLiveMessage() {
  const input = document.getElementById('chat-input');
  if (!input || !input.value.trim()) return;
  const feed = document.getElementById('chat-feed');
  const text = input.value.trim();
  feed.innerHTML += renderOutgoingMsg(text, 'Just now');
  input.value = '';
  feed.scrollTop = feed.scrollHeight;

  // Crisis detection
  if (text.toLowerCase().includes('suicide') || text.toLowerCase().includes('kill myself') || text.toLowerCase().includes('hopeless')) {
    setTimeout(() => {
      feed.innerHTML += `
        <div style="padding:10px; background:#FEECEE; border:1px solid #EF4444; border-radius:14px; font-size:11px; color:#EF4444;">
          <strong>🚨 Emergency Help is Available:</strong> You are not alone. Please dial <strong>988</strong> or click SOS Help.
        </div>
      `;
      feed.scrollTop = feed.scrollHeight;
    }, 500);
  } else {
    // Gentle peer response
    setTimeout(() => {
      feed.innerHTML += renderIncomingMsg('I hear you, Alex 💜 Thanks for sharing that with me.', 'Just now');
      feed.scrollTop = feed.scrollHeight;
    }, 1200);
  }
}

// 10. NEW JOURNAL ENTRY (Mockup 1.17.19 AM (1))
function renderJournalNew() {
  return `
    <div style="height:100%; padding:16px 18px; overflow-y:auto; background:#F8F8FD;">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
        <button onclick="loadScreen('home')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
        <button onclick="loadScreen('journal_done')" style="padding:6px 16px; background:#5E4BEE; color:#FFF; border:none; border-radius:16px; font-weight:700; font-size:12px; cursor:pointer;">Save</button>
      </div>

      <div style="text-align:center; margin-bottom:18px;">
        <h2 style="font-size:20px; font-weight:800; color:#191632;">New Journal Entry ✨</h2>
        <p style="font-size:11px; color:#6B6984;">Capture your thoughts and make them count. 💜</p>
      </div>

      <h4 style="font-size:13px; font-weight:700; margin-bottom:10px;">How are you feeling today?</h4>
      <div style="display:flex; justify-content:space-between; margin-bottom:18px;">
        ${renderSmallMood('Amazing', '😄', '#8B5CF6', true)}
        ${renderSmallMood('Good', '🙂', '#22C55E', false)}
        ${renderSmallMood('Okay', '😐', '#F59E0B', false)}
        ${renderSmallMood('Tired', '🥱', '#F97316', false)}
        ${renderSmallMood('Stressed', '😫', '#EF4444', false)}
      </div>

      <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">What's on your mind?</h4>
      <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:12px; margin-bottom:16px;">
        <textarea style="width:100%; height:80px; border:none; outline:none; font-size:13px; resize:none;">Today was a productive day. I finished my tasks, spent quality time with myself and learned something new. I'm grateful for all the little things. 💜</textarea>
        <div style="display:flex; justify-content:space-between; border-top:1px solid #ECEBF7; padding-top:8px; font-size:11px; color:#9E9DB5;">
          <span><b>B</b> <i>I</i> • 🔗 😊</span>
          <span>164 / 1000</span>
        </div>
      </div>

      <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">What are you grateful for today?</h4>
      <input type="text" value="Quiet morning coffee, positive match conversations." style="width:100%; padding:12px 14px; border-radius:16px; border:1px solid #ECEBF7; background:#FFF; font-size:12px; margin-bottom:18px;">

      <button onclick="loadScreen('journal_done')" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 6px 18px rgba(94,75,238,0.3); margin-bottom:10px;">
        Save Entry ➔
      </button>
      <button onclick="loadScreen('journal_done')" style="width:100%; height:48px; background:#FFF; border:1.5px solid #5E4BEE; color:#5E4BEE; border-radius:24px; font-size:13px; font-weight:700; cursor:pointer;">
        Save & Add to Daily Log
      </button>
    </div>
  `;
}

// 11. JOURNAL SAVED CONFIRMATION (Mockup 1.17.18 AM (3))
function renderJournalDone() {
  return `
    <div style="height:100%; padding:20px; overflow-y:auto; text-align:center; background:#F8F8FD;">
      <div style="width:90px; height:90px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:42px; margin:16px auto;">
        📖
      </div>
      <h2 style="font-size:24px; font-weight:800; color:#191632;">All set! ✨</h2>
      <p style="font-size:13px; color:#6B6984; margin:4px 0 20px 0;">
        Your entry has been saved successfully.<br>Great job reflecting today! 💜
      </p>

      <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:20px; padding:16px; text-align:left; margin-bottom:20px; box-shadow:0 4px 12px rgba(0,0,0,0.02);">
        <div style="font-size:11px; color:#9E9DB5; margin-bottom:6px;">May 24, 2026 • 10:32 PM</div>
        <p style="font-size:13px; color:#191632; line-height:1.4; margin-bottom:12px;">
          "Today was a productive day. I finished my tasks, spent quality time with myself and learned something new. I'm grateful for all the little things. 💜"
        </p>
        <div style="display:flex; gap:6px;">
          <span style="font-size:10px; background:#F3F3FA; padding:3px 8px; border-radius:8px;">General</span>
          <span style="font-size:10px; background:#F3F3FA; padding:3px 8px; border-radius:8px;">Gratitude</span>
          <span style="font-size:10px; background:#E7F9EE; color:#22C55E; font-weight:bold; padding:3px 8px; border-radius:8px;">Happy</span>
        </div>
      </div>

      <button onclick="loadScreen('home')" style="width:100%; height:52px; background:#5E4BEE; color:#FFF; border:none; border-radius:26px; font-size:15px; font-weight:700; cursor:pointer;">
        Done ➔
      </button>
    </div>
  `;
}

// 12. PROGRESS & STREAK (Mockup 1.17.20 AM (2))
function renderProgress() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD;">
      <div style="flex:1; overflow-y:auto; padding:16px 18px;">
        <div style="text-align:center; margin-bottom:16px;">
          <span style="font-size:36px;">📈</span>
          <h2 style="font-size:20px; font-weight:800; color:#191632;">Your Progress ✨</h2>
          <p style="font-size:11px; color:#6B6984;">Track your growth and celebrate wins.</p>
        </div>

        <!-- 72% Donut Card with Calculation Info -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:22px; padding:16px; margin-bottom:16px;">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
            <span style="font-size:12px; font-weight:800; color:#191632;">Weekly Wellness Index</span>
            <span onclick="showProgressFormulaModal()" style="font-size:11px; color:#5E4BEE; font-weight:bold; cursor:pointer; display:flex; align-items:center; gap:3px;">ℹ️ How it's calculated</span>
          </div>
          <div style="display:flex; align-items:center; gap:16px;">
            <div style="width:84px; height:84px; border-radius:50%; border:8px solid #5E4BEE; border-right-color:#ECEBF7; display:flex; flex-direction:column; align-items:center; justify-content:center; flex-shrink:0;">
              <strong style="font-size:18px; color:#191632;">72%</strong>
              <span style="font-size:8px; color:#9E9DB5; font-weight:bold;">ON TRACK</span>
            </div>
            <div>
              <h4 style="font-size:14px; font-weight:800; color:#191632;">You're doing great!</h4>
              <p style="font-size:11px; color:#6B6984; margin:2px 0 6px 0;">Consistency leads to transformation.</p>
              <span style="font-size:10px; background:#E8F8F0; color:#22C55E; font-weight:bold; padding:2px 8px; border-radius:8px;">↑ 12% from last week</span>
            </div>
          </div>
        </div>

        <!-- 16-Day Streak M-T-W-T-F-S-S -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:22px; padding:16px; margin-bottom:16px;">
          <div style="display:flex; justify-content:space-between; margin-bottom:12px;">
            <div>
              <span style="font-size:11px; color:#9E9DB5;">Your Streak</span>
              <div style="font-size:16px; font-weight:800; color:#191632;">🔥 16 days</div>
            </div>
            <span style="font-size:11px; color:#6B6984;">Keep your streak alive!</span>
          </div>
          <div style="display:flex; justify-content:space-between; text-align:center;">
            ${renderStreakDay('M', true)}
            ${renderStreakDay('T', true)}
            ${renderStreakDay('W', true)}
            ${renderStreakDay('T', true)}
            ${renderStreakDay('F', true)}
            ${renderStreakDay('S', true)}
            ${renderStreakDay('S', false)}
          </div>
        </div>

        <!-- Goals -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:22px; padding:16px; margin-bottom:16px;">
          <h4 style="font-size:13px; font-weight:800; margin-bottom:12px;">Goals Overview</h4>
          ${renderGoalBar('Improve Mental Well-being', 80, '#5E4BEE')}
          ${renderGoalBar('Personal Growth', 65, '#22C55E')}
          ${renderGoalBar('Stronger Relationships', 50, '#F59E0B')}
        </div>
      </div>
      ${renderBottomNav('progress')}
    </div>
  `;
}

function renderStreakDay(day, done) {
  return `
    <div>
      <div style="font-size:10px; font-weight:bold; color:${done ? '#5E4BEE' : '#9E9DB5'}; margin-bottom:4px;">${day}</div>
      <div style="width:30px; height:30px; border-radius:50%; background:${done ? '#5E4BEE' : '#FFF'}; border:1px solid ${done ? '#5E4BEE' : '#ECEBF7'}; color:#FFF; font-size:12px; display:flex; align-items:center; justify-content:center;">
        ${done ? '✓' : ''}
      </div>
    </div>
  `;
}

function renderGoalBar(title, pct, color) {
  return `
    <div style="margin-bottom:10px;">
      <div style="display:flex; justify-content:space-between; font-size:11px; font-weight:bold; margin-bottom:4px;">
        <span>${title}</span>
        <span style="color:${color};">${pct}%</span>
      </div>
      <div style="width:100%; height:6px; background:#ECEBF7; border-radius:3px; overflow:hidden;">
        <div style="width:${pct}%; height:100%; background:${color};"></div>
      </div>
    </div>
  `;
}

// 13. COMMUNITY SUPPORT CIRCLES (Mockup 1.17.20 AM)
function renderCommunity() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD;">
      <div style="flex:1; overflow-y:auto; padding:14px 18px;">
        <div style="text-align:center; margin-bottom:14px;">
          <span style="font-size:36px;">👥</span>
          <h2 style="font-size:20px; font-weight:800; color:#191632;">Community ✨</h2>
          <p style="font-size:11px; color:#6B6984;">You're not alone. We're all on this journey together.</p>
        </div>

        <input type="text" placeholder="Search topics, members, or posts" style="width:100%; padding:10px 16px; border-radius:20px; border:1px solid #ECEBF7; background:#FFF; font-size:12px; margin-bottom:14px;">

        <!-- Feed Item -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:20px; padding:14px; margin-bottom:12px;">
          <div style="display:flex; align-items:center; gap:8px; margin-bottom:8px;">
            <img src="../assets/mockups/home_dashboard_priya.jpeg" style="width:34px; height:34px; border-radius:50%; object-fit:cover;">
            <div>
              <strong style="font-size:12px;">Jessica M.</strong>
              <span style="background:#F0EEFF; color:#5E4BEE; font-size:9px; font-weight:bold; padding:2px 6px; border-radius:6px; margin-left:4px;">Top Contributor</span>
              <div style="font-size:9px; color:#9E9DB5;">2h ago • Mind & Well-being</div>
            </div>
          </div>
          <p style="font-size:12px; color:#191632; line-height:1.4; margin-bottom:10px;">
            Morning meditation has completely changed my day. Feeling more calm and focused than ever! 🌿
          </p>
          <div style="display:flex; gap:16px; font-size:11px; color:#6B6984;">
            <span>❤️ 128</span>
            <span>💬 24</span>
            <span style="margin-left:auto;">🔖</span>
          </div>
        </div>

        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:20px; padding:14px; margin-bottom:12px;">
          <div style="display:flex; align-items:center; gap:8px; margin-bottom:8px;">
            <img src="../assets/mockups/match_celebration.jpeg" style="width:34px; height:34px; border-radius:50%; object-fit:cover;">
            <div>
              <strong style="font-size:12px;">David L.</strong>
              <div style="font-size:9px; color:#9E9DB5;">5h ago • Goals</div>
            </div>
          </div>
          <p style="font-size:12px; color:#191632; line-height:1.4; margin-bottom:10px;">
            Just hit a major milestone—down 10 pounds! Consistency and small steps really work. 💪
          </p>
          <div style="display:flex; gap:16px; font-size:11px; color:#6B6984;">
            <span>❤️ 96</span>
            <span>💬 18</span>
            <span style="margin-left:auto;">🔖</span>
          </div>
        </div>
      </div>
      ${renderBottomNav('community')}
    </div>
  `;
}

// 14. SOS EMERGENCY HELP HUB (Mockup 1.17.17 AM)
function renderSos() {
  return `
    <div style="height:100%; padding:16px 18px; overflow-y:auto; background:#F8F8FD; text-align:center;">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
        <button onclick="loadScreen('home')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
        <span style="font-size:14px; font-weight:800; color:#EF4444;">SOS Help 🚨</span>
        <span onclick="showSimulatorToast('Confidential: All emergency calls & chats are 100% private. 🛡️')" style="font-size:11px; color:#5E4BEE; font-weight:bold; cursor:pointer;">How it works</span>
      </div>

      <h2 style="font-size:18px; font-weight:800; color:#191632; margin-top:10px;">You matter. We're here for you.</h2>
      <p style="font-size:12px; color:#6B6984; margin:4px 0 24px 0;">If you're feeling overwhelmed or in distress, reach out now. 💜</p>

      <!-- Pulsing Red SOS Button -->
      <div style="display:flex; justify-content:center; margin-bottom:20px;">
        <div onclick="showSimulatorToast('🚨 Calling 24/7 National Crisis Line (988)... Free & confidential.')" class="sos-pulse-circle" style="width:150px; height:150px; background:linear-gradient(135deg, #FF536B 0%, #EF4444 100%); border-radius:50%; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#FFF; cursor:pointer;">
          <span style="font-size:36px;">🚨</span>
          <strong style="font-size:15px; margin-top:4px;">I Need Help<br>Now</strong>
        </div>
      </div>

      <p style="font-size:11px; color:#6B6984;">Tap the button above if you need immediate support.</p>
      <p style="font-size:11px; color:#5E4BEE; font-weight:bold; margin-bottom:24px;">🔒 100% Confidential</p>

      <!-- 24/7 Helplines -->
      <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:20px; padding:14px; text-align:left; margin-bottom:16px;">
        <div style="font-size:12px; font-weight:800; color:#191632; margin-bottom:12px;">Talk to Someone Now (Free & 24/7)</div>
        
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <div>
            <strong style="font-size:12px;">24/7 Helpline: 988 / 14416</strong>
            <div style="font-size:10px; color:#6B6984;">US/Intl: <strong>988</strong> • India Tele-MANAS: <strong>14416</strong></div>
            <div style="font-size:10px; color:#22C55E; font-weight:bold;">🟢 Available Now • Free & Confidential</div>
          </div>
          <button onclick="showSosDialerModal()" style="padding:6px 14px; background:#5E4BEE; color:#FFF; border:none; border-radius:14px; font-size:11px; font-weight:bold; cursor:pointer;">Start Call</button>
        </div>

        <div style="display:flex; justify-content:space-between; align-items:center;">
          <div>
            <strong style="font-size:12px;">Crisis Text & Chat: 741741</strong>
            <div style="font-size:10px; color:#6B6984;">SMS <strong>741741</strong> • WhatsApp: <strong>+91 9999 666 555</strong></div>
            <div style="font-size:10px; color:#22C55E; font-weight:bold;">🟢 Available Now • Free SMS</div>
          </div>
          <button onclick="showSimulatorToast('💬 Connecting to Crisis Text Line (SMS HOME to 741741)... Free & confidential.')" style="padding:6px 14px; background:#5E4BEE; color:#FFF; border:none; border-radius:14px; font-size:11px; font-weight:bold; cursor:pointer;">Start Text</button>
        </div>
      </div>
    </div>
  `;
}

// 15. PROFILE & XP LEVEL 12
function renderProfile() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD;">
      <!-- Header -->
      <div style="padding:12px 18px 6px 18px; display:flex; justify-content:space-between; align-items:center;">
        <button onclick="loadScreen('home')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;">❮</button>
        <span style="font-size:15px; font-weight:800; color:#191632;">Profile & Growth 🌟</span>
        <button onclick="showSimulatorProfileSettings()" style="background:#FFF; border:1px solid #ECEBF7; border-radius:50%; width:36px; height:36px; cursor:pointer;" title="Settings">⚙️</button>
      </div>

      <div style="flex:1; overflow-y:auto; padding:10px 18px;">
        <!-- User Avatar & Greeting -->
        <div style="display:flex; align-items:center; gap:14px; margin-bottom:14px;">
          <div style="position:relative;">
            <img src="${currentUser.avatarUrl}" style="width:64px; height:64px; border-radius:50%; object-fit:cover; border:2px solid #5E4BEE;">
            <span style="position:absolute; bottom:2px; right:2px; width:14px; height:14px; background:#22C55E; border:2px solid #FFF; border-radius:50%;"></span>
          </div>
          <div>
            <h3 style="font-size:18px; font-weight:800; color:#191632;">Hi, ${currentUser.isAnonymous ? 'Kind Peer' : currentUser.name}! ✨</h3>
            <p style="font-size:11px; color:#6B6984;">Becoming the best version of yourself. 💜</p>
          </div>
        </div>

        <!-- Created ID Pill with Copy Button -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:16px; padding:12px 14px; margin-bottom:14px; display:flex; justify-content:space-between; align-items:center; box-shadow:0 2px 8px rgba(0,0,0,0.02);">
          <div>
            <span style="font-size:10px; color:#6B6984; font-weight:700; text-transform:uppercase;">Registered Unique ID</span>
            <div style="font-size:14px; font-weight:800; color:#5E4BEE; margin-top:2px;">${currentUser.id}</div>
          </div>
          <button onclick="copyUserIdToClipboard()" style="padding:6px 12px; background:#F0EEFF; border:1px solid #DDD6FE; border-radius:12px; font-size:11px; font-weight:700; color:#5E4BEE; cursor:pointer; display:flex; align-items:center; gap:4px;">
            📋 Copy ID
          </button>
        </div>

        <!-- Auto-Fetched Account Details Card -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:14px; margin-bottom:14px;">
          <div style="font-size:12px; font-weight:800; color:#191632; margin-bottom:8px;">Auto-Fetched Details</div>
          <div style="font-size:11px; color:#6B6984; line-height:1.6;">
            <div>📧 <strong>Email:</strong> ${currentUser.email}</div>
            <div>📍 <strong>Location:</strong> ${currentUser.location} (${currentUser.age} yrs)</div>
            <div>🌱 <strong>Bio:</strong> ${currentUser.bio}</div>
          </div>

          <div style="margin-top:10px;">
            <div style="font-size:10px; font-weight:bold; color:#191632; margin-bottom:4px;">Selected Struggles / Focus:</div>
            <div style="display:flex; flex-wrap:wrap; gap:4px; margin-bottom:8px;">
              ${currentUser.feelings.map(f => `<span style="background:#F0EEFF; color:#5E4BEE; padding:2px 8px; border-radius:8px; font-size:10px; font-weight:bold;">${f}</span>`).join('')}
            </div>

            <div style="font-size:10px; font-weight:bold; color:#191632; margin-bottom:4px;">Passions:</div>
            <div style="display:flex; flex-wrap:wrap; gap:4px;">
              ${currentUser.interests.map(i => `<span style="background:#F3F3FA; color:#191632; padding:2px 8px; border-radius:8px; font-size:10px;">${i}</span>`).join('')}
            </div>
          </div>
        </div>

        <!-- Anonymity Toggle Card -->
        <div style="padding:12px 14px; background:#FFF; border:1.5px solid ${currentUser.isAnonymous ? '#5E4BEE' : '#ECEBF7'}; border-radius:16px; display:flex; align-items:center; justify-content:space-between; margin-bottom:14px;">
          <div style="display:flex; align-items:center; gap:10px;">
            <div style="width:34px; height:34px; background:#F0EEFF; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:16px;">🎭</div>
            <div>
              <h4 style="font-size:12px; font-weight:700; color:#191632;">Anonymity Mode</h4>
              <p style="font-size:10px; color:#6B6984;">Show safe avatar & alias to peers</p>
            </div>
          </div>
          <input type="checkbox" ${currentUser.isAnonymous ? 'checked' : ''} onchange="toggleProfileAnonymity(this.checked)" style="width:18px; height:18px; accent-color:#5E4BEE; cursor:pointer;">
        </div>

        <!-- 4 Stat Badges -->
        <div style="display:grid; grid-template-columns:repeat(4, 1fr); gap:6px; margin-bottom:14px; text-align:center;">
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:8px 4px;">
            <div style="font-size:16px;">🔥</div>
            <strong style="font-size:14px; color:#191632;">${currentUser.streakDays}</strong>
            <div style="font-size:8px; color:#9E9DB5;">Streak</div>
          </div>
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:8px 4px;">
            <div style="font-size:16px;">🎯</div>
            <strong style="font-size:14px; color:#191632;">24</strong>
            <div style="font-size:8px; color:#9E9DB5;">Goals</div>
          </div>
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:8px 4px;">
            <div style="font-size:16px;">⏱️</div>
            <strong style="font-size:14px; color:#191632;">89</strong>
            <div style="font-size:8px; color:#9E9DB5;">Hours</div>
          </div>
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:8px 4px;">
            <div style="font-size:16px;">⭐</div>
            <strong style="font-size:14px; color:#191632;">4.8</strong>
            <div style="font-size:8px; color:#9E9DB5;">Score</div>
          </div>
        </div>

        <!-- Level 12 XP Card -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:12px; display:flex; align-items:center; gap:12px; margin-bottom:14px;">
          <div style="width:42px; height:42px; background:#5E4BEE; border-radius:12px; color:#FFF; display:flex; flex-direction:column; align-items:center; justify-content:center;">
            <span style="font-size:8px; opacity:0.8;">LEVEL</span>
            <strong style="font-size:15px;">${currentUser.level}</strong>
          </div>
          <div style="flex:1;">
            <div style="display:flex; justify-content:space-between; font-size:11px; font-weight:bold; margin-bottom:4px;">
              <span>Growth Explorer</span>
              <span style="color:#5E4BEE;">${currentUser.xp} / 3,000 XP</span>
            </div>
            <div style="width:100%; height:6px; background:#ECEBF7; border-radius:3px; overflow:hidden;">
              <div style="width:78%; height:100%; background:#5E4BEE;"></div>
            </div>
          </div>
        </div>

        <!-- 1. Wehere Plus Subscription Banner -->
        <div onclick="showWeherePlusSubscriptionModal()" style="background:linear-gradient(135deg, #2E1065 0%, #5E4BEE 100%); border-radius:18px; padding:14px; color:#FFF; margin-bottom:12px; display:flex; align-items:center; gap:12px; cursor:pointer; box-shadow:0 6px 16px rgba(94,75,238,0.25);">
          <div style="width:38px; height:38px; background:rgba(255,255,255,0.2); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px;">⭐</div>
          <div style="flex:1;">
            <div style="font-size:13px; font-weight:800;">Wehere Plus 🌟</div>
            <div style="font-size:10px; color:rgba(255,255,255,0.8);">Instant Voice Calling, Unlimited Rewinds & 100% Ad-Free.</div>
          </div>
          <button style="background:#FBBF24; color:#000; border:none; padding:6px 12px; border-radius:12px; font-size:11px; font-weight:800; cursor:pointer;">Upgrade</button>
        </div>

        <!-- 2. Campus & Corporate Hub Banner -->
        <div onclick="loadScreen('campus')" style="background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:14px; margin-bottom:14px; display:flex; align-items:center; gap:12px; cursor:pointer;">
          <div style="width:38px; height:38px; background:#F0FDF4; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px;">🏛️</div>
          <div style="flex:1;">
            <div style="font-size:13px; font-weight:800; color:#191632;">Campus & Corporate Hub</div>
            <div style="font-size:10px; color:#6B6984;">Join your university, college, or workplace wellness circle.</div>
          </div>
          <button style="background:none; border:1px solid #16A34A; color:#16A34A; padding:6px 10px; border-radius:12px; font-size:11px; font-weight:700; cursor:pointer;">Open Hub</button>
        </div>

        <!-- Sign Out Button -->
        <button onclick="handleSignOut()" style="width:100%; padding:12px; background:#FFF; border:1px solid #FCA5A5; color:#DC2626; border-radius:16px; font-size:12px; font-weight:700; cursor:pointer; margin-bottom:12px;">
          🚪 Sign Out
        </button>
      </div>
      ${renderBottomNav('profile')}
    </div>
  `;
}

function copyUserIdToClipboard() {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(currentUser.id);
  }
  showToast(`Copied ${currentUser.id} to clipboard!`);
}

function toggleProfileAnonymity(val) {
  currentUser.isAnonymous = val;
  userAnonymous = val;
  showToast(val ? 'Anonymity Enabled: Peers see safe alias' : 'Anonymity Disabled: Real name visible');
  loadScreen('profile');
}

function handleSignOut() {
  showToast('Logged out successfully.');
  loadScreen('login');
}

// MODERN CLEAN 5-TAB BOTTOM NAVIGATION
function renderBottomNav(activeTab) {
  return `
    <div class="bottom-nav-shell">
      <div class="nav-tab ${activeTab === 'home' ? 'active' : ''}" onclick="loadScreen('home')">
        <div class="nav-icon-wrap">🏠</div>
        <span class="nav-label">Home</span>
      </div>
      <div class="nav-tab ${activeTab === 'discover' ? 'active' : ''}" onclick="loadScreen('discover')">
        <div class="nav-icon-wrap">🧭</div>
        <span class="nav-label">Discover</span>
      </div>
      <div class="nav-tab ${activeTab === 'reflect' || activeTab === 'progress' ? 'active' : ''}" onclick="loadScreen('journal_new')">
        <div class="nav-icon-wrap">📔</div>
        <span class="nav-label">Reflect</span>
      </div>
      <div class="nav-tab ${activeTab === 'community' ? 'active' : ''}" onclick="loadScreen('community')">
        <div class="nav-icon-wrap">⭕</div>
        <span class="nav-label">Circles</span>
      </div>
      <div class="nav-tab ${activeTab === 'chat' ? 'active' : ''}" onclick="loadScreen('chat')">
        <div class="nav-icon-wrap">
          💬
          <span class="nav-badge">2</span>
        </div>
        <span class="nav-label">Chat</span>
      </div>
    </div>
  `;
}

function toggleMockupDrawer() {
  const drawer = document.getElementById('mockup-drawer');
  drawer.classList.toggle('open');
}

function initMockupDrawer() {
  const grid = document.getElementById('drawer-grid');
  grid.innerHTML = mockupsList.map(m => `
    <div class="mockup-card">
      <img src="${m.file}" alt="${m.name}">
      <p>${m.name}</p>
    </div>
  `).join('');
}

function showSimulatorToast(msg) {
  let toast = document.getElementById('simulator-toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'simulator-toast';
    toast.style.cssText = 'position:fixed; bottom:30px; left:50%; transform:translateX(-50%); background:#191632; color:#FFF; padding:12px 24px; border-radius:24px; font-size:13px; font-weight:700; box-shadow:0 12px 32px rgba(0,0,0,0.35); z-index:999999; display:flex; align-items:center; gap:8px; transition:all 0.3s cubic-bezier(0.16, 1, 0.3, 1); opacity:0; pointer-events:none; border:1px solid rgba(255,255,255,0.15);';
    document.body.appendChild(toast);
  }
  toast.innerHTML = msg;
  toast.style.opacity = '1';
  toast.style.transform = 'translateX(-50%) translateY(-10px)';
  clearTimeout(toast._timeout);
  toast._timeout = setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(-50%) translateY(0)';
  }, 2600);
}

function showSimulatorNotifications() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-notif-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.45); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end; animation:fadeIn 0.2s ease;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:24px 24px 0 0; padding:20px; box-shadow:0 -8px 24px rgba(0,0,0,0.15);">
      <div style="width:36px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
        <strong style="font-size:15px; color:#191632;">Supportive Alerts 🔔</strong>
        <span onclick="document.getElementById('sim-notif-modal').remove()" style="font-size:12px; font-weight:700; color:#5E4BEE; cursor:pointer;">Close</span>
      </div>
      <div style="display:flex; flex-direction:column; gap:10px;">
        <div style="padding:10px 12px; background:#F0EEFF; border-radius:14px; font-size:12px;">
          <strong>Riya replied to your chat 💜</strong>
          <div style="font-size:11px; color:#6B6984; margin-top:2px;">“Small wins matter a lot! Celebrate them always ✨” • 4m ago</div>
        </div>
        <div style="padding:10px 12px; background:#FEF3C7; border-radius:14px; font-size:12px;">
          <strong>16-Day Streak Milestone 🔥</strong>
          <div style="font-size:11px; color:#B45309; margin-top:2px;">Consistency leads to transformation. Keep going Alex!</div>
        </div>
      </div>
    </div>
  `;
  container.appendChild(modal);
}

function showSimulatorSafetyModal() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-safety-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.45); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:24px 24px 0 0; padding:20px; box-shadow:0 -8px 24px rgba(0,0,0,0.15);">
      <div style="width:36px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <div style="font-size:14px; font-weight:bold; margin-bottom:12px; color:#191632;">Safe Space & Privacy 🛡️</div>
      <div style="display:flex; flex-direction:column; gap:8px;">
        <button onclick="document.getElementById('sim-safety-modal').remove(); showSimulatorToast('Safe Space Pledge: Treat each other with kindness and non-judgment. 💜');" style="width:100%; text-align:left; padding:10px 12px; background:#F8F8FD; border:1px solid #ECEBF7; border-radius:14px; font-size:12px; font-weight:600; cursor:pointer;">🛡️ Safe Space Community Guidelines</button>
        <button onclick="document.getElementById('sim-safety-modal').remove(); showSimulatorToast('User blocked. Conversation removed.'); loadScreen('home');" style="width:100%; text-align:left; padding:10px 12px; background:#FFF7ED; border:1px solid #FED7AA; border-radius:14px; font-size:12px; font-weight:600; color:#C2410C; cursor:pointer;">🚫 Block & Remove Peer</button>
        <button onclick="document.getElementById('sim-safety-modal').remove(); showSimulatorToast('Report submitted for human moderator review.');" style="width:100%; text-align:left; padding:10px 12px; background:#FEF2F2; border:1px solid #FECACA; border-radius:14px; font-size:12px; font-weight:600; color:#DC2626; cursor:pointer;">⚠️ Report Inappropriate Content</button>
      </div>
      <button onclick="document.getElementById('sim-safety-modal').remove()" style="width:100%; margin-top:12px; padding:10px; background:#ECEBF7; border:none; border-radius:14px; font-size:12px; font-weight:bold; cursor:pointer;">Cancel</button>
    </div>
  `;
  container.appendChild(modal);
}

function showSimulatorProfileSettings() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-settings-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.45); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:24px 24px 0 0; padding:20px; box-shadow:0 -8px 24px rgba(0,0,0,0.15);">
      <div style="width:36px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <strong style="font-size:15px; color:#191632;">Settings & Privacy ⚙️</strong>
      <div style="display:flex; flex-direction:column; gap:10px; margin-top:14px;">
        <div style="display:flex; justify-content:space-between; align-items:center; padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <span style="font-size:12px; font-weight:600;">Instant Anonymity Mode</span>
          <input type="checkbox" ${currentUser.isAnonymous ? 'checked' : ''} onchange="currentUser.isAnonymous = this.checked; loadScreen('profile'); showSimulatorToast('Anonymity Mode: ' + (this.checked ? 'Enabled 🔒' : 'Disabled'));">
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <span style="font-size:12px; font-weight:600;">Push Notifications</span>
          <input type="checkbox" checked onchange="showSimulatorToast('Notification preferences updated.')">
        </div>
        <button onclick="document.getElementById('sim-settings-modal').remove(); loadScreen('login'); showSimulatorToast('Logged out securely.');" style="width:100%; padding:10px; background:#FEECEE; border:1px solid #FCA5A5; color:#DC2626; border-radius:14px; font-size:12px; font-weight:700; cursor:pointer;">Log Out</button>
      </div>
      <button onclick="document.getElementById('sim-settings-modal').remove()" style="width:100%; margin-top:10px; padding:10px; background:#ECEBF7; border:none; border-radius:14px; font-size:12px; font-weight:bold; cursor:pointer;">Done</button>
    </div>
  `;
  container.appendChild(modal);
}

function sendIcebreakerQuickPrompt(promptText) {
  const feed = document.getElementById('chat-feed');
  if (!feed) return;
  feed.innerHTML += renderOutgoingMsg(promptText, 'Just now');
  feed.scrollTop = feed.scrollHeight;
  showSimulatorToast('Wellness icebreaker sent ✨');
  setTimeout(() => {
    feed.innerHTML += renderIncomingMsg('That\'s such a lovely question! For me, a quiet morning coffee always centers my mind ☕ How about you?', 'Just now');
    feed.scrollTop = feed.scrollHeight;
  }, 1200);
}

function showWeherePlusSubscriptionModal() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-subscription-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.55); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:26px 26px 0 0; padding:22px; max-height:85%; overflow-y:auto; box-shadow:0 -10px 30px rgba(0,0,0,0.25);">
      <div style="width:40px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
        <div style="display:flex; align-items:center; gap:8px;">
          <span style="font-size:22px;">👑</span>
          <strong style="font-size:18px; color:#191632;">Wehere Plus 🌟</strong>
        </div>
        <span onclick="document.getElementById('sim-subscription-modal').remove()" style="font-size:18px; color:#9E9DB5; cursor:pointer;">✕</span>
      </div>
      <p style="font-size:11px; color:#6B6984; margin-bottom:14px;">Instant voice calling, unlimited rewinds & an ad-free wellness haven.</p>

      <div style="display:flex; flex-direction:column; gap:10px; margin-bottom:16px;">
        <div style="display:flex; gap:10px; align-items:flex-start; padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <span style="font-size:16px; background:#E0F2FE; padding:6px; border-radius:50%;">📞</span>
          <div style="font-size:11px; line-height:1.3;">
            <strong style="color:#191632;">Instant Voice Calling:</strong> Skip the 3-day wait. Connect with empathetic verified peers via private voice calls anytime.
          </div>
        </div>
        <div style="display:flex; gap:10px; align-items:flex-start; padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <span style="font-size:16px; background:#EDE9FE; padding:6px; border-radius:50%;">⏪</span>
          <div style="font-size:11px; line-height:1.3;">
            <strong style="color:#191632;">Unlimited Rewinds:</strong> Passed a compatible peer by accident? Rewind anytime without limits.
          </div>
        </div>
        <div style="display:flex; gap:10px; align-items:flex-start; padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <span style="font-size:16px; background:#DCFCE7; padding:6px; border-radius:50%;">🛡️</span>
          <div style="font-size:11px; line-height:1.3;">
            <strong style="color:#191632;">100% Ad-Free Healing:</strong> Zero banners or sponsored partner cards across all community feeds.
          </div>
        </div>
      </div>

      <!-- Pricing Plans -->
      <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:16px;">
        <div style="border:2px solid #5E4BEE; background:#F0EEFF; padding:12px; border-radius:16px; text-align:left;">
          <span style="font-size:9px; background:#5E4BEE; color:#FFF; padding:2px 6px; border-radius:6px; font-weight:bold;">BEST VALUE</span>
          <div style="font-size:15px; font-weight:800; color:#191632; margin-top:4px;">₹199 / mo</div>
          <div style="font-size:10px; color:#6B6984;">Annual (₹2,388/yr)</div>
        </div>
        <div style="border:1px solid #ECEBF7; background:#FFF; padding:12px; border-radius:16px; text-align:left;">
          <span style="font-size:9px; color:#6B6984; font-weight:bold;">FLEXIBLE</span>
          <div style="font-size:15px; font-weight:800; color:#191632; margin-top:4px;">₹299 / mo</div>
          <div style="font-size:10px; color:#6B6984;">Billed monthly</div>
        </div>
      </div>

      <button onclick="document.getElementById('sim-subscription-modal').remove(); showSimulatorToast('🎉 Welcome to Wehere Plus! Voice Calling & Unlimited Rewinds Unlocked.');" style="width:100%; height:48px; background:#5E4BEE; color:#FFF; border:none; border-radius:24px; font-size:14px; font-weight:800; cursor:pointer; box-shadow:0 6px 16px rgba(94,75,238,0.3);">
        Start 7-Day Free Trial ➔
      </button>
      <p style="font-size:9px; color:#9E9DB5; text-align:center; margin-top:8px;">Cancel anytime in Google Play Store / Apple App Store.</p>
    </div>
  `;
  container.appendChild(modal);
}

function showDeckFiltersModal() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-filters-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.5); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:26px 26px 0 0; padding:22px; max-height:85%; overflow-y:auto; box-shadow:0 -10px 30px rgba(0,0,0,0.25);">
      <div style="width:40px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
        <strong style="font-size:16px; color:#191632;">Discovery Deck Filters ☲</strong>
        <span onclick="document.getElementById('sim-filters-modal').remove()" style="font-size:18px; color:#9E9DB5; cursor:pointer;">✕</span>
      </div>

      <div style="font-size:12px; font-weight:700; color:#191632; margin-bottom:8px;">Category Feed:</div>
      <div style="display:flex; gap:6px; flex-wrap:wrap; margin-bottom:16px;">
        <span style="background:#5E4BEE; color:#FFF; padding:6px 12px; border-radius:14px; font-size:11px; font-weight:bold; cursor:pointer;">For You ✨</span>
        <span style="background:#F0EEFF; color:#5E4BEE; padding:6px 12px; border-radius:14px; font-size:11px; font-weight:bold; cursor:pointer;">New</span>
        <span style="background:#F0EEFF; color:#5E4BEE; padding:6px 12px; border-radius:14px; font-size:11px; font-weight:bold; cursor:pointer;">Active Now 🟢</span>
        <span style="background:#F0EEFF; color:#5E4BEE; padding:6px 12px; border-radius:14px; font-size:11px; font-weight:bold; cursor:pointer;">Near You 📍</span>
      </div>

      <div style="font-size:12px; font-weight:700; color:#191632; margin-bottom:8px;">Mutual Connection Priority:</div>
      <div style="display:flex; gap:6px; flex-wrap:wrap; margin-bottom:16px;">
        <span style="background:#F8F8FD; border:1px solid #ECEBF7; padding:6px 10px; border-radius:12px; font-size:11px;">Burnout Relief 💜</span>
        <span style="background:#F8F8FD; border:1px solid #ECEBF7; padding:6px 10px; border-radius:12px; font-size:11px;">Quiet Listening 🌿</span>
        <span style="background:#F8F8FD; border:1px solid #ECEBF7; padding:6px 10px; border-radius:12px; font-size:11px;">Personal Growth 🌱</span>
        <span style="background:#F8F8FD; border:1px solid #ECEBF7; padding:6px 10px; border-radius:12px; font-size:11px;">Career Pressure 💼</span>
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; padding:12px; background:#F8F8FD; border-radius:16px; margin-bottom:16px;">
        <div>
          <div style="font-size:12px; font-weight:bold; color:#191632;">Online Right Now Only</div>
          <div style="font-size:10px; color:#6B6984;">Show peers ready for immediate live conversation</div>
        </div>
        <input type="checkbox" checked style="width:18px; height:18px; accent-color:#5E4BEE;">
      </div>

      <div style="display:flex; gap:10px;">
        <button onclick="document.getElementById('sim-filters-modal').remove(); showSimulatorToast('Deck reset to default.');" style="flex:1; height:44px; background:#F3F3FA; border:1px solid #ECEBF7; border-radius:22px; font-size:13px; font-weight:bold; cursor:pointer;">Reset</button>
        <button onclick="document.getElementById('sim-filters-modal').remove(); showSimulatorToast('Filters applied! Showing relevant peers ✨');" style="flex:1; height:44px; background:#5E4BEE; color:#FFF; border:none; border-radius:22px; font-size:13px; font-weight:bold; cursor:pointer;">Apply Filters</button>
      </div>
    </div>
  `;
  container.appendChild(modal);
}

function showProgressFormulaModal() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-progress-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.5); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:26px 26px 0 0; padding:22px; max-height:85%; overflow-y:auto; box-shadow:0 -10px 30px rgba(0,0,0,0.25);">
      <div style="width:40px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
        <div style="display:flex; align-items:center; gap:8px;">
          <span style="font-size:20px;">🧮</span>
          <strong style="font-size:16px; color:#191632;">How Progress is Calculated</strong>
        </div>
        <span onclick="document.getElementById('sim-progress-modal').remove()" style="font-size:18px; color:#9E9DB5; cursor:pointer;">✕</span>
      </div>
      <p style="font-size:11px; color:#6B6984; line-height:1.4; margin-bottom:14px;">
        Your <strong>72% Weekly Wellness Index</strong> is a gentle, multi-dimensional score calculated transparently from 3 key wellness pillars:
      </p>

      <div style="display:flex; flex-direction:column; gap:10px; margin-bottom:16px;">
        <div style="padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <div style="display:flex; justify-content:space-between; font-size:12px;">
            <strong>🎯 Self-Care Goals (50% Weight)</strong>
            <span style="color:#5E4BEE; font-weight:800;">+37.5%</span>
          </div>
          <p style="font-size:10px; color:#6B6984; margin:2px 0 6px 0;">Completed 3 of 4 active wellness goals (75% completion).</p>
          <div style="width:100%; height:5px; background:#ECEBF7; border-radius:3px; overflow:hidden;"><div style="width:75%; height:100%; background:#5E4BEE;"></div></div>
        </div>

        <div style="padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <div style="display:flex; justify-content:space-between; font-size:12px;">
            <strong>🔥 Streak Consistency (30% Weight)</strong>
            <span style="color:#F59E0B; font-weight:800;">+21.4%</span>
          </div>
          <p style="font-size:10px; color:#6B6984; margin:2px 0 6px 0;">Active 5 out of 7 rolling days this week (71% consistency).</p>
          <div style="width:100%; height:5px; background:#ECEBF7; border-radius:3px; overflow:hidden;"><div style="width:71%; height:100%; background:#F59E0B;"></div></div>
        </div>

        <div style="padding:10px 12px; background:#F8F8FD; border-radius:14px;">
          <div style="display:flex; justify-content:space-between; font-size:12px;">
            <strong>🧘 Reflection Habits (20% Weight)</strong>
            <span style="color:#10B981; font-weight:800;">+20.0%</span>
          </div>
          <p style="font-size:10px; color:#6B6984; margin:2px 0 6px 0;">Logged regular mindful journaling & mood check-ins (100%).</p>
          <div style="width:100%; height:5px; background:#ECEBF7; border-radius:3px; overflow:hidden;"><div style="width:100%; height:100%; background:#10B981;"></div></div>
        </div>
      </div>

      <div style="background:#F0EEFF; border:1px solid #DDD6FE; border-radius:14px; padding:10px 12px; font-size:11px; margin-bottom:16px;">
        <strong>Total Formula:</strong><br>
        (75% × 0.50) + (71.4% × 0.30) + (100% × 0.20) = <strong>72.7% ≈ 72% On Track</strong>
      </div>

      <button onclick="document.getElementById('sim-progress-modal').remove()" style="width:100%; height:44px; background:#5E4BEE; color:#FFF; border:none; border-radius:22px; font-size:13px; font-weight:bold; cursor:pointer;">
        Got It ✨
      </button>
    </div>
  `;
  container.appendChild(modal);
}

function showSosDialerModal() {
  const container = document.getElementById('screen-container');
  if (!container) return;
  const modal = document.createElement('div');
  modal.id = 'sim-sos-dialer-modal';
  modal.style.cssText = 'position:absolute; inset:0; background:rgba(0,0,0,0.55); z-index:99999; display:flex; flex-direction:column; justify-content:flex-end;';
  modal.innerHTML = `
    <div style="background:#FFF; border-radius:26px 26px 0 0; padding:22px; max-height:85%; overflow-y:auto; box-shadow:0 -10px 30px rgba(0,0,0,0.25);">
      <div style="width:40px; height:4px; background:#E5E7EB; border-radius:2px; margin:0 auto 14px auto;"></div>
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
        <div style="display:flex; align-items:center; gap:8px;">
          <span style="font-size:22px;">🚨</span>
          <strong style="font-size:16px; color:#EF4444;">Select Helpline to Call</strong>
        </div>
        <span onclick="document.getElementById('sim-sos-dialer-modal').remove()" style="font-size:18px; color:#9E9DB5; cursor:pointer;">✕</span>
      </div>
      <p style="font-size:11px; color:#6B6984; margin-bottom:14px;">Free, 24/7 confidential mental health support lines:</p>

      <div style="display:flex; flex-direction:column; gap:10px; margin-bottom:16px;">
        <div onclick="document.getElementById('sim-sos-dialer-modal').remove(); showSimulatorToast('📞 Dialing 988 Suicide & Crisis Lifeline (US & Global)... Free & Confidential.');" style="padding:12px; background:#FEF2F2; border:1px solid #FECACA; border-radius:14px; cursor:pointer; display:flex; justify-content:space-between; align-items:center;">
          <div>
            <strong style="font-size:13px; color:#DC2626;">988 Suicide & Crisis Lifeline</strong>
            <div style="font-size:10px; color:#6B6984;">United States & International • Free 24/7</div>
          </div>
          <span style="background:#DC2626; color:#FFF; padding:4px 10px; border-radius:10px; font-size:11px; font-weight:bold;">Dial 988</span>
        </div>

        <div onclick="document.getElementById('sim-sos-dialer-modal').remove(); showSimulatorToast('📞 Dialing Tele-MANAS (14416 Toll-Free India)... Free & 24/7 in 20+ Languages.');" style="padding:12px; background:#F0FDF4; border:1px solid #BBF7D0; border-radius:14px; cursor:pointer; display:flex; justify-content:space-between; align-items:center;">
          <div>
            <strong style="font-size:13px; color:#16A34A;">Tele-MANAS (Govt of India)</strong>
            <div style="font-size:10px; color:#6B6984;">Toll-Free 24/7 (14416 / 1800 891 4416)</div>
          </div>
          <span style="background:#16A34A; color:#FFF; padding:4px 10px; border-radius:10px; font-size:11px; font-weight:bold;">Dial 14416</span>
        </div>

        <div onclick="document.getElementById('sim-sos-dialer-modal').remove(); showSimulatorToast('📞 Dialing Vandrevala Foundation (+91 9999 666 555)...');" style="padding:12px; background:#F8F8FD; border:1px solid #ECEBF7; border-radius:14px; cursor:pointer; display:flex; justify-content:space-between; align-items:center;">
          <div>
            <strong style="font-size:13px; color:#191632;">Vandrevala Foundation</strong>
            <div style="font-size:10px; color:#6B6984;">+91 9999 666 555 • 24/7 Free Counselor Aid</div>
          </div>
          <span style="background:#5E4BEE; color:#FFF; padding:4px 10px; border-radius:10px; font-size:11px; font-weight:bold;">Call</span>
        </div>
      </div>

      <button onclick="document.getElementById('sim-sos-dialer-modal').remove()" style="width:100%; height:44px; background:#ECEBF7; border:none; border-radius:22px; font-size:13px; font-weight:bold; cursor:pointer;">
        Cancel
      </button>
    </div>
  `;
  container.appendChild(modal);
}

function renderCampusCorporate() {
  return `
    <div style="height:100%; display:flex; flex-direction:column; background:#F8F8FD;">
      <!-- Header -->
      <div style="padding:12px 18px; background:#FFF; border-bottom:1px solid #ECEBF7; display:flex; align-items:center; gap:10px;">
        <button onclick="loadScreen('profile')" style="background:none; border:none; font-size:16px; color:#5E4BEE; cursor:pointer;">❮</button>
        <strong style="font-size:15px; color:#191632;">Campus & Corporate Hub 🏛️</strong>
      </div>

      <div style="flex:1; overflow-y:auto; padding:14px 18px;">
        <!-- Banner -->
        <div style="background:linear-gradient(135deg, #064E3B 0%, #059669 100%); border-radius:20px; padding:18px; color:#FFF; margin-bottom:16px;">
          <span style="font-size:9px; background:rgba(255,255,255,0.2); padding:2px 8px; border-radius:8px; font-weight:bold;">INSTITUTIONAL WELLNESS</span>
          <h3 style="font-size:16px; font-weight:bold; margin:6px 0 4px 0;">Safe Peer Networks for Campuses & Workplaces</h3>
          <p style="font-size:11px; color:rgba(255,255,255,0.8); line-height:1.4;">Zero-Knowledge private wellness circles for universities, colleges, and enterprise teams.</p>
        </div>

        <!-- Join Existing with Code -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:16px; margin-bottom:16px;">
          <strong style="font-size:13px; color:#191632;">🔑 Have an Access Code?</strong>
          <p style="font-size:11px; color:#6B6984; margin:2px 0 10px 0;">Enter your school, college, or company wellness code:</p>
          <div style="display:flex; gap:8px;">
            <input id="campus-code-input" type="text" placeholder="e.g. STANFORD2026" style="flex:1; padding:10px 12px; border:1px solid #ECEBF7; border-radius:14px; font-size:12px; text-transform:uppercase;">
            <button onclick="handleCampusCodeJoin()" style="padding:10px 16px; background:#16A34A; color:#FFF; border:none; border-radius:14px; font-size:12px; font-weight:bold; cursor:pointer;">Join</button>
          </div>
        </div>

        <!-- Institutional Pillars -->
        <div style="font-size:13px; font-weight:800; color:#191632; margin-bottom:8px;">Why Institutions Partner with Wehere:</div>
        <div style="display:flex; flex-direction:column; gap:8px; margin-bottom:16px;">
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:10px 12px; font-size:11px;">
            <strong>🔒 Zero-Knowledge Anonymity:</strong> Never share employee or student chat logs with HR or administration.
          </div>
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:10px 12px; font-size:11px;">
            <strong>🎓 Verified Org Circles:</strong> Dedicated private circles exclusive to your campus or workplace email domain.
          </div>
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:10px 12px; font-size:11px;">
            <strong>📊 Aggregated Pulse Trends:</strong> High-level wellness sentiment tracking to combat exam or quarterly burnout.
          </div>
          <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:14px; padding:10px 12px; font-size:11px;">
            <strong>🚨 Custom EAP Escalation:</strong> Direct escalation routes to your on-campus counseling center or corporate EAP.
          </div>
        </div>

        <!-- Request Pilot Form -->
        <div style="background:#FFF; border:1px solid #ECEBF7; border-radius:18px; padding:16px; margin-bottom:20px;">
          <strong style="font-size:13px; color:#191632;">Request an Institutional Pilot ✨</strong>
          <p style="font-size:11px; color:#6B6984; margin:2px 0 10px 0;">30-day free pilot for your school, college, or workplace.</p>
          <input id="inq-org" type="text" placeholder="Organization / Campus Name" style="width:100%; padding:8px 12px; border:1px solid #ECEBF7; border-radius:12px; font-size:11px; margin-bottom:8px;">
          <input id="inq-email" type="email" placeholder="Official Work / Campus Email" style="width:100%; padding:8px 12px; border:1px solid #ECEBF7; border-radius:12px; font-size:11px; margin-bottom:10px;">
          <button onclick="handlePilotInquirySubmit()" style="width:100%; padding:10px; background:#059669; color:#FFF; border:none; border-radius:16px; font-size:12px; font-weight:bold; cursor:pointer;">
            Submit Pilot Request ➔
          </button>
        </div>
      </div>
    </div>
  `;
}

function handleCampusCodeJoin() {
  const input = document.getElementById('campus-code-input');
  const code = input ? input.value.trim().toUpperCase() : '';
  if (!code) {
    showSimulatorToast('Please enter an access code.');
    return;
  }
  showSimulatorToast(`✅ Verified! Welcome to the "${code}" Campus Wellness Circle.`);
  if (input) input.value = '';
}

function handlePilotInquirySubmit() {
  const org = document.getElementById('inq-org')?.value.trim();
  const email = document.getElementById('inq-email')?.value.trim();
  if (!org || !email) {
    showSimulatorToast('Please provide your organization name and email.');
    return;
  }
  showSimulatorToast('🎉 Pilot request submitted! Our partnerships team will reach out within 24h.');
  document.getElementById('inq-org').value = '';
  document.getElementById('inq-email').value = '';
}

// Initial Launch
window.addEventListener('DOMContentLoaded', () => {
  loadScreen('splash');
  initMockupDrawer();
});

