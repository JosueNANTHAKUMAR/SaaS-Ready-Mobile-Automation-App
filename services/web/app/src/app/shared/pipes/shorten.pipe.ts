import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'shorten'
})
export class ShortenPipe implements PipeTransform {
  transform(value: string, maxlenght = 50): string {
    if (value.length <= maxlenght) {
      return value;
    }
    return value.substring(0, maxlenght) + '…';
  }
}