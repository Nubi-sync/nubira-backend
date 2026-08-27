import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Nubira Creation Cloud Backend is Live & Healthy! 🚀';
  }
}
