<template>
  <div class="excel-viewer">
    <!-- File Upload Section -->
    <div class="upload-section">
      <input
        type="file"
        @change="handleFileUpload"
        accept=".xlsx,.xls"
        class="file-input"
      />
      <div v-if="loading" class="loading">Loading...</div>
    </div>

    <!-- Excel Online Viewer -->
    <div v-if="fileUrl" class="viewer-section">
      <iframe
        :src="getExcelViewerUrl"
        frameborder="0"
        class="excel-frame"
      ></iframe>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onBeforeMount } from 'vue'

const loading = ref(false)
const fileUrl = ref<string | null>(null)

// Convert file to URL
const handleFileUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  loading.value = true
  try {
    // Create a blob URL for the file
    const url = URL.createObjectURL(file)
    fileUrl.value = url
  } catch (error) {
    console.error('Error processing file:', error)
    alert('Error processing file')
  } finally {
    loading.value = false
  }
}

// Generate Excel Online viewer URL
const getExcelViewerUrl = computed(() => {
  if (!fileUrl.value) return ''

  const baseUrl = 'https://view.officeapps.live.com/op/embed.aspx?src='
  const params = new URLSearchParams({
    src: fileUrl.value,
    wdAllowInteractivity: 'False',
    wdHideGridlines: 'False',
    wdHideHeaders: 'False',
    wdDownloadButton: 'True',
    wdPrint: 'True'
  })

  return `${baseUrl}${params.toString()}`
})

// Clean up the blob URL when component is unmounted
onBeforeMount(() => {
  if (fileUrl.value) {
    URL.revokeObjectURL(fileUrl.value)
  }
})
</script>

<style scoped>
.excel-viewer {
  width: 100%;
  padding: 20px;
}

.upload-section {
  margin-bottom: 20px;
}

.file-input {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
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
</style>
