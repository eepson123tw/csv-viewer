<!-- eslint-disable vue/require-v-for-key -->
<script setup lang="ts">
import { ref, type Ref, type PropType } from 'vue'
import * as XLSX from 'xlsx'
const props = defineProps<{
  title?: string
  likes?: number
}>()

interface ExcelData {
  [key: string]: string | number | Date | null
}

interface FileReaderEvent extends ProgressEvent {
  target: FileReader & EventTarget
}

type SheetData = Array<Array<string | number | Date | null>>

// Typed refs
const data: Ref<SheetData> = ref([])
const workbook: Ref<XLSX.WorkBook | null> = ref(null)
const sheetNames: Ref<string[]> = ref([])
const currentSheet: Ref<string> = ref('')
const error: Ref<string> = ref('')
const fileInputRef: Ref<HTMLInputElement | null> = ref(null)

// Event handlers with TypeScript
const handleFileUpload = (event: Event): void => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (e: ProgressEvent<FileReader>) => {
    try {
      const fileData = new Uint8Array(e.target?.result as ArrayBuffer)
      workbook.value = XLSX.read(fileData, {
        type: 'array',
        cellDates: true,
        cellStyles: true,
      })

      sheetNames.value = workbook.value.SheetNames
      currentSheet.value = sheetNames.value[0]
      loadSheet(currentSheet.value)
      error.value = ''
    } catch (err: unknown) {
      error.value = `Error reading Excel file: ${err instanceof Error ? err.message : 'Unknown error'}`
      console.error('Error:', err)
    }
  }
  reader.onerror = (err: ProgressEvent<FileReader>) => {
    error.value = `Error reading file: ${err}`
  }
  reader.readAsArrayBuffer(file)
}

const loadSheet = (sheetName: string): void => {
  if (!workbook.value) return
  const worksheet = workbook.value.Sheets[sheetName]
  data.value = XLSX.utils.sheet_to_json(worksheet, {
    header: 1,
    defval: '',
  }) as SheetData
}

const changeSheet = (): void => {
  loadSheet(currentSheet.value)
}

const triggerFileInput = (): void => {
  fileInputRef.value?.click()
}

const printRow = (row: (string | number | Date | null)[]) => {
  console.log(row)
}
</script>
<template>
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">
        Excel Viewer<span>-{{ props.title }}</span>
      </h2>
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
          accept=".xlsx,.xls"
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

      <div v-if="sheetNames.length > 0" class="sheet-selector-container">
        <select v-model="currentSheet" @change="changeSheet" class="sheet-selector">
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
            <tr v-for="(row, rowIndex) in data.slice(1)" :key="rowIndex" @click="printRow(row)">
              <td v-for="(cell, cellIndex) in row" :key="cellIndex">
                {{ cell?.toString() || '' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="!data.length && !error" class="empty-state">
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
  </div>
</template>
