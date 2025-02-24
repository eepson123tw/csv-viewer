<template>
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">CSV Viewer<span>-paperparse</span></h2>
      <div class="upload-container">
        <button class="btn-upload" @click="triggerFileInput">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="upload-icon"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
          >
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
            <polyline points="17 8 12 3 7 8" />
            <line x1="12" y1="3" x2="12" y2="15" />
          </svg>
          Upload Excel File
        </button>
        <input
          ref="fileInputRef"
          type="file"
          @change="handleFileUpload"
          accept=".csv"
          class="hidden"
        />
      </div>
    </div>

    <div class="card-content">
      <div v-if="error" class="alert-error">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="alert-icon"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
        >
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        {{ error }}
      </div>
    </div>

    <div v-if="csvData.length > 0" class="table-container">
      <table class="modern-table">
        <thead>
          <tr>
            <th v-for="header in headers" :key="header">{{ header }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, index) in csvData" :key="index">
            <td v-for="header in headers" :key="header">{{ row[header] }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="!csvData.length && !error" class="empty-state">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="empty-icon"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
      >
        <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z" />
        <polyline points="13 2 13 9 20 9" />
      </svg>
      <p>Upload an Excel file to view its contents</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, type Ref } from 'vue'
import Papa from 'papaparse'

type CSVRow = Record<string, string | number>
type Headers = string[]

const csvData = ref<CSVRow[]>([])
const headers = ref<Headers>([])
const error = ref<string | null>(null)
const fileInputRef: Ref<HTMLInputElement | null> = ref(null)

const triggerFileInput = (): void => {
  fileInputRef.value?.click()
}
const readCSV = (file: File): Promise<CSVRow[]> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()

    reader.onload = (e) => {
      const csvText = e.target?.result

      Papa.parse(csvText as unknown as File, {
        header: true,
        complete: (results) => {
          console.log('Complete', results.data.length, 'records.')
          resolve(results.data as CSVRow[])
        },
        error: (error) => {
          reject(error)
        },
      })
    }

    reader.onerror = () => reject(new Error('Failed to read file'))
    reader.readAsText(file)
  })
}

const handleFileUpload = async (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  error.value = null
  csvData.value = []
  headers.value = []

  try {
    const parsedData = await readCSV(file)
    headers.value = Object.keys(parsedData[0] || {})
    csvData.value = parsedData
  } catch (err) {
    error.value = err instanceof Error ? err.message : '解析錯誤'
    console.error('Error parsing CSV:', err)
  }
}
</script>

<style scoped>
.csv-uploader {
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

.error-message {
  color: red;
  margin-top: 10px;
}

.data-display {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
}

th,
td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
}

th {
  background-color: #f4f4f4;
}

tr:nth-child(even) {
  background-color: #f8f8f8;
}
</style>
