import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('articles')
export class Article {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  art_no: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0, nullable: true })
  piece_rate?: number;

  @Column({ default: true, nullable: true })
  is_active?: boolean;

  @CreateDateColumn({ nullable: true })
  created_at?: Date;

  get name(): string {
    return this.art_no || 'Garment';
  }

  get defaultPieceRate(): number {
    return Number(this.piece_rate) || 0;
  }
}
