<!-- eslint-disable vue/require-v-for-key -->
<script setup lang="ts">
import { ref } from 'vue'
import * as XLSX from 'https://unpkg.com/xlsx/xlsx.mjs'

const data = ref([])
const workbook = ref(null)
const sheetNames = ref([])
const currentSheet = ref('')
const error = ref('')
const fileInputRef = ref(null)

const handleFileUpload = (event) => {
  const file = event.target.files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const fileData = new Uint8Array(e.target.result)
      workbook.value = XLSX.read(fileData, {
        type: 'array',
        cellDates: true,
        cellStyles: true,
      })

      sheetNames.value = workbook.value.SheetNames
      currentSheet.value = sheetNames.value[0]
      loadSheet(currentSheet.value)
      error.value = ''
    } catch (err) {
      error.value = 'Error reading Excel file: ' + err.message
      console.error('Error:', err)
    }
  }
  reader.onerror = (err) => {
    error.value = 'Error reading file: ' + err
  }
  reader.readAsArrayBuffer(file)
}

const loadSheet = (sheetName) => {
  if (!workbook.value) return
  const worksheet = workbook.value.Sheets[sheetName]
  data.value = XLSX.utils.sheet_to_json(worksheet, {
    header: 1,
    defval: '',
  })
}

const changeSheet = () => {
  loadSheet(currentSheet.value)
}

const triggerFileInput = () => {
  fileInputRef.value?.click()
}
</script>

<template>
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">Excel Viewer</h2>
      <div class="upload-container">
        <button class="btn-upload" @click="triggerFileInput">
          <svg xmlns="http://www.w3.org/2000/svg" class="upload-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
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
          accept=".xlsx,.xls"
          class="hidden"
        />
      </div>
    </div>

    <div class="card-content">
      <div v-if="error" class="alert-error">
        <svg xmlns="http://www.w3.org/2000/svg" class="alert-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        {{ error }}
      </div>

      <div v-if="sheetNames.length > 0" class="sheet-selector-container">
        <select
          v-model="currentSheet"
          @change="changeSheet"
          class="sheet-selector"
        >
          <option v-for="sheet in sheetNames" :key="sheet" :value="sheet">
            {{ sheet }}
          </option>
        </select>
      </div>

      <div v-if="data.length > 0" class="table-container">
        <table class="modern-table">
          <thead>
            <tr>
              <th v-for="(header, index) in data[0]" :key="index">
                {{ header || `Column ${index + 1}` }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, rowIndex) in data.slice(1)" :key="rowIndex">
              <td v-for="(cell, cellIndex) in row" :key="cell+cellIndex">
                {{ cell?.toString() || '' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="!data.length && !error" class="empty-state">
        <svg xmlns="http://www.w3.org/2000/svg" class="empty-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z" />
          <polyline points="13 2 13 9 20 9" />
        </svg>
        <p>Upload an Excel file to view its contents</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.card {
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  max-width: 1200px;
  margin: 2rem auto;
  overflow: hidden;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.card-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.card-content {
  padding: 1.5rem;
  max-height: 65vh;
  overflow: scroll;
}

.btn-upload {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: #2563eb;
  color: white;
  border: none;
  border-radius: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}

.btn-upload:hover {
  background: #1d4ed8;
}

.upload-icon {
  width: 1.25rem;
  height: 1.25rem;
}

.hidden {
  display: none;
}

.alert-error {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
  background: #fef2f2;
  border: 1px solid #fee2e2;
  border-radius: 0.375rem;
  color: #ef4444;
  margin-bottom: 1rem;
}

.alert-icon {
  width: 1.25rem;
  height: 1.25rem;
}

.sheet-selector-container {
  margin-bottom: 1.5rem;
}

.sheet-selector {
  appearance: none;
  background-color: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.375rem;
  padding: 0.5rem 2.5rem 0.5rem 0.75rem;
  font-size: 0.875rem;
  line-height: 1.25rem;
  min-width: 200px;
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
  background-position: right 0.5rem center;
  background-repeat: no-repeat;
  background-size: 1.5em 1.5em;
}

.sheet-selector:focus {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
}

.table-container {
  overflow-x: auto;
  border-radius: 0.5rem;
  border: 1px solid #e5e7eb;
}

.modern-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 0.875rem;
}

.modern-table thead {
  background-color: #f9fafb;
}

.modern-table th {
  font-weight: 500;
  padding: 0.75rem 1rem;
  color: #374151;
  border-bottom: 1px solid #e5e7eb;
}

.modern-table td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #e5e7eb;
  color: #111827;
}

.modern-table tbody tr:hover {
  background-color: #f9fafb;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 1rem;
  text-align: center;
  color: #6b7280;
}

.empty-icon {
  width: 3rem;
  height: 3rem;
  margin-bottom: 1rem;
  stroke-width: 1.5;
}

@media (max-width: 640px) {
  .card-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }

  .btn-upload {
    width: 100%;
    justify-content: center;
  }
}
</style>
