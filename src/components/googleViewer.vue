<template>
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">Google Drive Excel Viewer</h2>
    </div>

    <div class="auth-section p-2">
      <!-- This div will be used for the Google Sign-In button -->
      <div v-if="!isAuthenticated" id="g_id_signin" class="g-signin2"></div>

      <!-- Fallback manual sign-in button in case the Google button doesn't render -->
      <button
        v-if="!isAuthenticated && showManualSignIn"
        @click="handleManualSignIn"
        class="google-auth-btn"
      >
        Sign in with Google
      </button>

      <div v-if="isAuthenticated" class="authenticated-section">
        <p>Connected as: {{ userEmail }}</p>
        <button @click="loadDriveFiles" class="load-files-btn" :disabled="filesLoading">
          {{ filesLoading ? 'Loading...' : 'Load My Files' }}
        </button>
        <button @click="signOut" class="sign-out-btn" :disabled="signOutLoading">
          {{ signOutLoading ? 'Signing out...' : 'Sign Out' }}
        </button>
      </div>
    </div>

    <div v-if="files.length > 0" class="file-list-section p-2">
      <h3>Select an Excel File:</h3>
      <ul class="file-list">
        <li
          v-for="file in files"
          :key="file.id"
          @click="selectFile(file)"
          :class="{ selected: selectedFile && selectedFile.id === file.id }"
        >
          <img :src="file.iconLink" alt="file icon" class="file-icon" />
          <span>{{ file.name }}</span>
        </li>
      </ul>

      <button
        v-if="selectedFile"
        @click="viewSelectedFile"
        class="view-file-btn"
        :disabled="viewerLoading"
      >
        {{ viewerLoading ? 'Preparing file...' : 'View Selected File' }}
      </button>
    </div>

    <div v-if="error" class="error-message">
      {{ error }}
    </div>

    <div v-if="viewerUrl" class="viewer-section">
      <iframe
        :src="viewerUrl"
        class="excel-frame"
        sandbox="allow-scripts allow-forms allow-popups allow-top-navigation-by-user-activation allow-same-origin"
        @load="handleIframeLoad"
      ></iframe>
    </div>

    <div v-if="messages.length" class="message-log">
      <h3>Log:</h3>
      <ul>
        <li v-for="(message, index) in messages" :key="index">
          {{ message }}
        </li>
      </ul>
    </div>
  </div>
</template>
<!-- eslint-disable @typescript-eslint/no-explicit-any -->
<script setup lang="ts">
import { ref, onMounted } from 'vue'

// Define interfaces for Google API types
interface GoogleDriveFile {
  id: string
  name: string
  mimeType: string
  iconLink: string
  webViewLink?: string
  webContentLink?: string
}

interface GoogleApiError {
  message?: string
  error?: string
  details?: string
}

interface GoogleTokenResponse {
  access_token: string
  expires_in: number
  scope: string
  token_type: string
}

interface GoogleCredential {
  client_id: string
  credential: string
  select_by: string
}

// Augment the window interface to include Google Identity Services
declare global {
  interface Window {
    google: {
      accounts: {
        id: {
          initialize: (config: any) => void
          renderButton: (parent: HTMLElement, options: any) => void
          prompt: () => void
        }
        oauth2: {
          initTokenClient: (config: any) => {
            requestAccessToken: (options?: { prompt?: string }) => Promise<GoogleTokenResponse>
          }
        }
      }
    }
    gapi: {
      load: (api: string, callback: () => void) => void
      client: {
        init: (config: any) => Promise<void>
        drive: {
          files: {
            list: (params: any) => Promise<any>
            get: (params: any) => Promise<any>
          }
        }
        setToken: (token: { access_token?: string } | null) => void
      }
    }
  }
}

// Google API configuration - Use environment variables
const CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID
const API_KEY = import.meta.env.VITE_GOOGLE_API_KEY
const DISCOVERY_DOCS = ['https://www.googleapis.com/discovery/v1/apis/drive/v3/rest']
const SCOPES = 'https://www.googleapis.com/auth/drive.readonly'

// Maximum log messages to display
const MAX_LOG_MESSAGES = 50

// Component state
const isAuthenticated = ref<boolean>(false)
const authLoading = ref<boolean>(false)
const signOutLoading = ref<boolean>(false)
const filesLoading = ref<boolean>(false)
const viewerLoading = ref<boolean>(false)
const userEmail = ref<string>('')
const files = ref<GoogleDriveFile[]>([])
const selectedFile = ref<GoogleDriveFile | null>(null)
const viewerUrl = ref<string>('')
const error = ref<string>('')
const messages = ref<string[]>([])
const tokenClient = ref<any>(null)
const accessToken = ref<string>('')
const showManualSignIn = ref<boolean>(false)

// Check for tokens in URL (for redirect flow)
onMounted(() => {
  logMessage('Component mounted, initializing...')

  // Check if we have a token in the URL (from redirect flow)
  const hash = window.location.hash
  if (hash.includes('access_token')) {
    const params = new URLSearchParams(hash.substring(1))
    const token = params.get('access_token')
    if (token) {
      // Remove the token from the URL to prevent leaks
      window.history.replaceState({}, document.title, window.location.pathname)

      // Use the token
      accessToken.value = token
      window.gapi.client.setToken({ access_token: token })
      isAuthenticated.value = true
      logMessage('Authentication successful from redirect')

      // Get user email
      fetchUserEmail()
    }
  }

  loadGoogleAPIs()

  // Show manual sign-in button after a delay if Google button doesn't load
  setTimeout(() => {
    if (!isAuthenticated.value && !document.querySelector('#g_id_signin iframe')) {
      showManualSignIn.value = true
      logMessage('Google Sign-In button failed to load, showing manual button')
    }
  }, 3000)
})

function loadGoogleAPIs() {
  logMessage('Loading Google APIs...')

  // Load the GIS Library
  const gisScript = document.createElement('script')
  gisScript.src = 'https://accounts.google.com/gsi/client'
  gisScript.async = true
  gisScript.defer = true
  gisScript.onload = () => {
    logMessage('Google Identity Services loaded')

    // Load the GAPI Library
    const gapiScript = document.createElement('script')
    gapiScript.src = 'https://apis.google.com/js/api.js'
    gapiScript.async = true
    gapiScript.defer = true
    gapiScript.onload = () => {
      logMessage('Google API Client loaded')
      window.gapi.load('client', initializeGapiClient)
    }
    gapiScript.onerror = () => {
      handleError('Failed to load Google API Client')
    }
    document.body.appendChild(gapiScript)
  }
  gisScript.onerror = () => {
    handleError('Failed to load Google Identity Services')
  }
  document.body.appendChild(gisScript)
}

async function initializeGapiClient() {
  try {
    await window.gapi.client.init({
      apiKey: API_KEY,
      discoveryDocs: DISCOVERY_DOCS,
    })

    logMessage('Google API client initialized')
    initializeGIS()
  } catch (error) {
    const apiError = error as GoogleApiError
    logMessage(
      'Failed to initialize Google API client: ' +
        (apiError.message || apiError.error || 'Unknown error'),
    )
    handleError('Failed to initialize Google API client')
  }
}

function initializeGIS() {
  try {
    // Initialize the token client with redirect mode (no popup)
    tokenClient.value = window.google.accounts.oauth2.initTokenClient({
      client_id: CLIENT_ID,
      scope: SCOPES,
      callback: handleTokenResponse,
      // Use an empty string for prompt to use redirect instead of popup
      prompt: '',
    })

    // Initialize the ID service
    window.google.accounts.id.initialize({
      client_id: CLIENT_ID,
      callback: handleCredentialResponse,
      auto_select: false,
    })

    // Render the Sign In button
    try {
      const signInElement = document.getElementById('g_id_signin')
      if (signInElement) {
        window.google.accounts.id.renderButton(signInElement, {
          type: 'standard',
          theme: 'outline',
          size: 'large',
          text: 'signin_with',
          shape: 'rectangular',
          logo_alignment: 'left',
          width: 250,
        })
      } else {
        logMessage('Sign-in element not found')
        showManualSignIn.value = true
      }
    } catch (buttonError) {
      logMessage('Error rendering sign-in button: ' + String(buttonError))
      showManualSignIn.value = true
    }

    logMessage('Google Identity Services initialized')
  } catch (error) {
    const apiError = error as GoogleApiError
    logMessage(
      'Failed to initialize Google Identity Services: ' +
        (apiError.message || apiError.error || 'Unknown error'),
    )
    handleError('Failed to initialize authentication services')
    showManualSignIn.value = true
  }
}

function handleManualSignIn() {
  if (tokenClient.value) {
    tokenClient.value.requestAccessToken()
  } else {
    handleError('Authentication not initialized yet. Please try again in a moment.')
  }
}

function handleCredentialResponse(response: GoogleCredential) {
  logMessage('Received credential response, requesting access token')
  // After getting the credential, we need to get an access token
  if (tokenClient.value) {
    tokenClient.value.requestAccessToken()
  }
}

function handleTokenResponse(tokenResponse: GoogleTokenResponse) {
  if (tokenResponse.access_token) {
    // Set the access token in GAPI
    window.gapi.client.setToken({ access_token: tokenResponse.access_token })
    accessToken.value = tokenResponse.access_token
    isAuthenticated.value = true

    // Get the user email
    fetchUserEmail()

    logMessage('Authentication successful')
  } else {
    handleError('Failed to obtain access token')
  }
}

async function fetchUserEmail() {
  try {
    const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: {
        Authorization: `Bearer ${accessToken.value}`,
      },
    })

    if (response.ok) {
      const data = await response.json()
      userEmail.value = data.email
      logMessage(`Connected as: ${userEmail.value}`)
    } else {
      logMessage('Failed to fetch user information')
    }
  } catch (error) {
    logMessage('Error fetching user email')
  }
}

function signOut() {
  signOutLoading.value = true
  try {
    // Clear the token from GAPI
    window.gapi.client.setToken(null)
    accessToken.value = ''
    isAuthenticated.value = false
    userEmail.value = ''
    files.value = []
    selectedFile.value = null
    viewerUrl.value = ''

    logMessage('Signed out successfully')

    // Reload the Google Identity Services
    window.google.accounts.id.prompt()
  } catch (error) {
    handleError('Failed to sign out')
  } finally {
    signOutLoading.value = false
  }
}

async function loadDriveFiles() {
  if (!isAuthenticated.value) {
    handleError('Please sign in first')
    return
  }

  filesLoading.value = true
  logMessage('Loading Excel files from Google Drive...')
  files.value = []
  selectedFile.value = null

  try {
    // Search for Excel files only
    const response = await window.gapi.client.drive.files.list({
      pageSize: 50,
      fields: 'files(id, name, mimeType, iconLink, webViewLink)',
      q: "mimeType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' or mimeType='application/vnd.ms-excel'",
    })

    files.value = response.result.files || []
    logMessage(`Found ${files.value.length} Excel files`)

    if (files.value.length === 0) {
      logMessage('No Excel files found in your Google Drive')
    }
  } catch (error) {
    const apiError = error as GoogleApiError
    const errorMessage = apiError.message || apiError.error || 'Unknown error'
    logMessage('Failed to load files: ' + errorMessage)
    handleError('Failed to load files from Google Drive')
  } finally {
    filesLoading.value = false
  }
}

function selectFile(file: GoogleDriveFile) {
  selectedFile.value = file
  logMessage(`Selected file: ${file.name}`)
}

async function viewSelectedFile() {
  if (!selectedFile.value) return

  viewerLoading.value = true
  logMessage(`Preparing to view file: ${selectedFile.value.name}`)

  try {
    // Get sharing permissions to create a publicly accessible URL
    const response = await window.gapi.client.drive.files.get({
      fileId: selectedFile.value.id,
      fields: 'webContentLink,webViewLink',
    })

    // Try different viewer options
    const viewerUrls = []

    // Option 1: Microsoft Office Viewer
    if (response.result.webContentLink) {
      viewerUrls.push(
        `https://view.officeapps.live.com/op/embed.aspx?src=${encodeURIComponent(response.result.webContentLink)}`,
      )
    }

    // Option 2: Direct Google Drive preview (may require permission)
    viewerUrls.push(`https://drive.google.com/file/d/${selectedFile.value.id}/preview`)

    // Option 3: Google Docs Viewer
    viewerUrls.push(
      `https://docs.google.com/viewer?url=${encodeURIComponent(response.result.webViewLink || '')}&embedded=true`,
    )

    // https://docs.google.com/spreadsheets/d/15LWckUHWOidBmSweqlt0Yp9KlNxg6lZU/edit?usp=drive_link&ouid=101600230923984204515&rtpof=true&sd=true
    // Option 4: Temporary access URL with token
    const exportUrl = `https://www.googleapis.com/drive/v3/files/${selectedFile.value.id}?alt=media&access_token=${accessToken.value}`
    viewerUrls.push(
      `https://view.officeapps.live.com/op/embed.aspx?src=${encodeURIComponent(exportUrl)}`,
    )

    // Use the first URL option (will try others if this fails)
    viewerUrl.value = viewerUrls[1]
    logMessage('Using Microsoft Office viewer to display file')
  } catch (error) {
    const apiError = error as GoogleApiError
    const errorMessage = apiError.message || apiError.error || 'Unknown error'
    logMessage('Failed to prepare file for viewing: ' + errorMessage)
    handleError('Failed to prepare file for viewing')

    // Fallback to Google Drive preview URL
    if (selectedFile.value) {
      viewerUrl.value = `https://drive.google.com/file/d/${selectedFile.value.id}/preview`
      logMessage('Using fallback Google Drive preview')
    }
  } finally {
    viewerLoading.value = false
  }
}

function handleIframeLoad() {
  if (selectedFile.value) {
    logMessage(`File ${selectedFile.value.name} loaded successfully`)
  }
}

function handleError(message: string) {
  error.value = message
  setTimeout(() => {
    error.value = ''
  }, 5000)
}

function logMessage(message: string) {
  const timestamp = new Date().toLocaleTimeString()
  messages.value.push(`[${timestamp}] ${message}`)

  // Limit log messages to prevent performance issues
  if (messages.value.length > MAX_LOG_MESSAGES) {
    messages.value = messages.value.slice(-MAX_LOG_MESSAGES)
  }
}
</script>

<style scoped>
.card {
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.card-header {
  background-color: #f5f5f5;
  padding: 15px;
  border-bottom: 1px solid #ddd;
}

.card-title {
  margin: 0;
  font-size: 1.5rem;
}

.p-2 {
  padding: 1rem;
}

.auth-section {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  margin-bottom: 15px;
}

.google-auth-btn {
  display: inline-flex;
  align-items: center;
  background-color: #4285f4;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  margin-top: 10px;
}

.authenticated-section {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin-top: 10px;
}

.load-files-btn {
  background-color: #34a853;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}

.load-files-btn:disabled {
  background-color: #a8d8b4;
  cursor: not-allowed;
}

.sign-out-btn {
  background-color: #ea4335;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}

.sign-out-btn:disabled {
  background-color: #f5a8a2;
  cursor: not-allowed;
}

.file-list-section {
  margin-top: 20px;
}

.file-list {
  list-style: none;
  padding: 0;
  max-height: 300px;
  overflow-y: auto;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.file-list li {
  display: flex;
  align-items: center;
  padding: 10px;
  border-bottom: 1px solid #eee;
  cursor: pointer;
}

.file-list li:hover {
  background-color: #f9f9f9;
}

.file-list li.selected {
  background-color: #e3f2fd;
}

.file-icon {
  width: 20px;
  height: 20px;
  margin-right: 10px;
}

.view-file-btn {
  margin-top: 15px;
  background-color: #4285f4;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}

.view-file-btn:disabled {
  background-color: #a0c1ff;
  cursor: not-allowed;
}

.error-message {
  margin-top: 10px;
  padding: 10px;
  background-color: #ffebee;
  color: #c62828;
  border-radius: 4px;
}

.viewer-section {
  width: 100%;
  height: 600px;
  margin-top: 20px;
}

.excel-frame {
  width: 100%;
  height: 100%;
  border: 1px solid #ddd;
}

.message-log {
  margin-top: 20px;
  padding: 15px;
  background-color: #f5f5f5;
  border-radius: 4px;
  max-height: 300px;
  overflow-y: auto;
}
</style>
