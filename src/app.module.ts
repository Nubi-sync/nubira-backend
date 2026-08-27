import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { AdminModule } from './admin/admin.module';
import { LinemanModule } from './lineman/lineman.module';
import { StoreModule } from './store/store.module';
import { ProductionModule } from './production/production.module';
import { DispatchModule } from './dispatch/dispatch.module';
import { UsersModule } from './users/users.module';
import { ScannerModule } from './scanner/scanner.module';
import { AuditModule } from './audit/audit.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DB_HOST'),
        port: parseInt(configService.get<string>('DB_PORT') ?? '5432', 10),
        username: configService.get<string>('DB_USER'),
        password: configService.get<string>('DB_PASSWORD'),
        database: configService.get<string>('DB_NAME'),
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        synchronize: false, // Production safety: do not alter existing Supabase tables on startup
        ssl: configService.get<string>('DB_SSL') === 'true' || configService.get<string>('DB_HOST')?.includes('supabase') || configService.get<string>('DB_HOST')?.includes('pooler') ? { rejectUnauthorized: false } : false,
      }),
      inject: [ConfigService],
    }),
    AuthModule,
    AdminModule,
    LinemanModule,
    StoreModule,
    ProductionModule,
    DispatchModule,
    UsersModule,
    ScannerModule,
    AuditModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
