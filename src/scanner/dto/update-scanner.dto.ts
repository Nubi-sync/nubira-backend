import { PartialType } from '@nestjs/mapped-types';
import { CreateScannerDto } from './create-scanner.dto';

export class UpdateScannerDto extends PartialType(CreateScannerDto) {}
