import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Bundle } from './bundle.entity';

@Entity('wage_ledger')
export class WageLedger {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'lineman_id' })
  lineman: User;

  @ManyToOne(() => Bundle)
  @JoinColumn({ name: 'bundle_id' })
  bundle: Bundle;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @CreateDateColumn()
  created_at: Date;
}
