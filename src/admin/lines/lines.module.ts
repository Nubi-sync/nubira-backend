import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LinesService } from './lines.service';
import { LinesController } from './lines.controller';
import { Line } from './entities/line.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Line])],
  controllers: [LinesController],
  providers: [LinesService],
  exports: [LinesService, TypeOrmModule]
})
export class LinesModule {}
