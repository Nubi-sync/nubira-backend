import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum UserRole {
  ADMIN = 'ADMIN',
  LINEMAN = 'LINEMAN',
  STORE = 'STORE',
  PRODUCTION = 'PRODUCTION',
  DISPATCH = 'DISPATCH',
}

@Entity('profiles')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  username: string;

  @Column({ nullable: true, select: false })
  password?: string;

  @Column({ nullable: true })
  name?: string;

  @Column({
    type: 'text',
    default: UserRole.LINEMAN,
  })
  role: UserRole;

  @Column({ nullable: true })
  line_no?: string;

  @CreateDateColumn({ nullable: true })
  created_at?: Date;
}
