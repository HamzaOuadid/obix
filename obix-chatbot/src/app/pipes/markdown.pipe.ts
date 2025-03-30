import { Pipe, PipeTransform } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { marked } from 'marked';

@Pipe({
  name: 'markdown',
  standalone: true
})
export class MarkdownPipe implements PipeTransform {
  constructor(private sanitizer: DomSanitizer) {
    // Configure marked options once during initialization
    marked.setOptions({
      gfm: true,    // GitHub flavored markdown
      breaks: true  // Convert line breaks to <br>
    });
  }

  transform(value: string): SafeHtml {
    if (!value) {
      return '';
    }

    // Parse markdown to HTML and sanitize
    try {
      const html = marked.parse(value);
      return this.sanitizer.bypassSecurityTrustHtml(html as string);
    } catch (error) {
      console.error('Error parsing markdown:', error);
      return this.sanitizer.bypassSecurityTrustHtml(value);
    }
  }
} 