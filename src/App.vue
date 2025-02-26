<!-- eslint-disable vue/require-v-for-key -->
<script setup lang="ts">
import xlsxViewer from '@/components/xlsxViewer.vue'
import papaparseViewer from '@/components/papaparseViewer.vue'
import ExcelViewer from '@/components/onedriveViewer.vue'
import GoogleViewer from '@/components/googleViewer.vue'
// import fastcsvViewer from '@/components/fastcsvViewer.vue';
</script>
<template>
  <xlsxViewer title="XLSX"></xlsxViewer>
  <papaparseViewer></papaparseViewer>
  <ExcelViewer></ExcelViewer>
  <GoogleViewer></GoogleViewer>
</template>
