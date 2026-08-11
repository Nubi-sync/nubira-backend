import { Module } from '@nestjs/common';
import { LinemanController } from './lineman.controller';
import { LinemanService } from './lineman.service';

@Module({
  controllers: [LinemanController],
  providers: [LinemanService]
})
export class LinemanModule {}
