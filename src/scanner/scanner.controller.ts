import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ScannerService } from './scanner.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('scanner')
@UseGuards(AuthGuard('jwt'))
export class ScannerController {
  constructor(private readonly scannerService: ScannerService) {}

  @Post('sync')
  async syncScans(@Request() req: any, @Body() body: any) {
    const { payloads } = body;
    // payloads is an array of offline scans: [{ barcode, context, timestamp, ... }]
    
    if (!payloads || !Array.isArray(payloads)) {
      return { success: 0, failed: 0, errors: ['Invalid payload format'] };
    }

    return this.scannerService.processSyncPayload(req.user, payloads);
  }
}
