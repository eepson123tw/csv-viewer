<template>
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">Excel Viewer<span></span></h2>
    </div>
    <div class="p-2">
      <h3>Option 1: Enter Public Excel URL</h3>
      <input
        v-model="publicUrl"
        type="text"
        placeholder="https://github.com/eepson123tw/csv-viewer/raw/refs/heads/master/public/test3.xlsx"
        class="url-input"
        @input="handleUrlInput"
      />
    </div>

    <div v-if="viewerUrl" class="viewer-section">
      <iframe
        :src="viewerUrl"
        frameborder="0"
        class="excel-frame"
        @load="handleIframeLoad"
      ></iframe>
    </div>

    <div v-if="messages.length" class="message-log">
      <h3>Interaction Log:</h3>
      <ul>
        <li v-for="(message, index) in messages" :key="index">
          {{ message }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const loading = ref(false)
const error = ref('')
const messages = ref<string[]>([])
const publicUrl = ref('')
const viewerUrl = ref('')

// Handle public URL input
const handleUrlInput = () => {
  if (!publicUrl.value) {
    viewerUrl.value = ''
    return
  }

  try {
    const url = new URL(publicUrl.value)
    const baseUrl = 'https://view.officeapps.live.com/op/embed.aspx?src='
    viewerUrl.value = `${baseUrl}${encodeURIComponent(publicUrl.value)}`
    error.value = ''
  } catch (e) {
    error.value = 'Please enter a valid URL'
    viewerUrl.value = ''
  }
}

// Handle file upload
const handleFileUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  loading.value = true
  error.value = ''

  try {
    // For demonstration, using a public URL
    // In production, you would upload the file to your server here
    error.value = 'File upload requires server implementation. Please use a public URL instead.'
    messages.value.push(
      `[${new Date().toLocaleTimeString()}] Note: Local file upload requires server implementation`,
    )

    // Example server upload code (commented out):
    /*
    const formData = new FormData()
    formData.append('file', file)
    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData
    })
    const { url } = await response.json()
    viewerUrl.value = `https://view.officeapps.live.com/op/embed.aspx?src=${encodeURIComponent(url)}`
    */
  } catch (err) {
    console.error('Error processing file:', err)
    error.value = 'Error processing file. Please try again.'
  } finally {
    loading.value = false
  }
}

const handleIframeLoad = () => {
  messages.value.push(`[${new Date().toLocaleTimeString()}] Excel viewer loaded`)
}
</script>

<style scoped>
.excel-viewer {
  width: 100%;
  padding: 20px;
}

.upload-section {
  margin-bottom: 20px;
}

.url-input,
.file-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  margin-bottom: 10px;
}

.error-message {
  color: red;
  margin-top: 5px;
}

.loading {
  margin-top: 10px;
}

.viewer-section {
  width: 100%;
  height: 600px;
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

.p-2 {
  padding: 0.25rem;
  width: 80%;
}
</style>
