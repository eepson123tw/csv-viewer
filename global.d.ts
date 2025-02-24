/* eslint-disable @typescript-eslint/no-explicit-any */
declare module 'papaparse' {

interface ParseConfig {
  delimiter?: string;
  newline?: string;
  header?: boolean;
  dynamicTyping?: boolean;
  preview?: number;
  encoding?: string;
  complete?: (results: ParseResult<any>) => void;
  error?: (error: Error) => void;
}

interface ParseResult<T> {
  data: T[];
  errors: any[];
  meta: {
	delimiter: string;
	linebreak: string;
	aborted: boolean;
	truncated: boolean;
	cursor: number;
  };
}

export function parse(file: File | string | NodeJS.ReadableStream, config?: ParseConfig): ParseResult<any>;
}
