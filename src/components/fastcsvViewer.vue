<template>
  <div class="csv-uploader">
    <div class="upload-section">
      <input
        type="file"
        ref="fileInput"
        accept=".csv"
        @change="handleFileUpload"
        class="file-input"
      />
      <p v-if="error" class="error-message">{{ error }}</p>
    </div>

    <div v-if="csvData.length" class="data-display">
      <h3>CSV 內容</h3>
      <table>
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
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { parse } from '@fast-csv/parse'

// 定義類型
type CSVRow = Record<string, string | number>
type Headers = string[]

// 定義響應式變數
const csvData = ref<CSVRow[]>([])
const headers = ref<Headers>([])
const error = ref<string | null>(null)

// 文件上傳處理函數
const handleFileUpload = (event: Event): void => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  error.value = null
  csvData.value = []
  headers.value = []

  const reader = new FileReader()

  reader.onload = (e: ProgressEvent<FileReader>): void => {
    const rows: CSVRow[] = []
    const result = e.target?.result

    if (typeof result !== 'string') {
      error.value = '檔案內容格式錯誤'
      return
    }

    parse({
      headers: true,
      skipRows: 0,
    })
      .on('error', (err: Error) => {
        error.value = `解析錯誤: ${err.message}`
      })
      .on('headers', (parsedHeaders: Headers) => {
        headers.value = parsedHeaders
      })
      .on('data', (row: CSVRow) => {
        rows.push(row)
      })
      .on('end', () => {
        csvData.value = rows
      })
  }

  reader.onerror = (): void => {
    error.value = '檔案讀取錯誤'
  }

  reader.readAsText(file)
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
