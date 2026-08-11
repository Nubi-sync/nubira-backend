import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductionOrder, POStatus } from './entities/production-order.entity';
import { Bundle, BundleStatus } from '../lineman/entities/bundle.entity';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/entities/user.entity';
import { Article } from './articles/entities/article.entity';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(ProductionOrder)
    private readonly poRepository: Repository<ProductionOrder>,
    @InjectRepository(Bundle)
    private readonly bundleRepository: Repository<Bundle>,
    @InjectRepository(Article)
    private readonly articleRepository: Repository<Article>,
    private readonly usersService: UsersService,
    private readonly auditService: AuditService,
  ) {}

  async createProductionOrder(dto: any, adminUser: any) {
    const { articleName, quantity, assignedLinemanId, pieceRate } = dto;
    
    const lineman = await this.usersService.findById(assignedLinemanId);
    if (!lineman || lineman.role !== UserRole.LINEMAN) {
      throw new BadRequestException('Invalid Lineman ID');
    }

    const po = this.poRepository.create({
      article_no: articleName,
      total_quantity: quantity,
      piece_rate: pieceRate,
      assignedLineman: lineman,
      status: POStatus.NEW,
    });

    const savedPo = await this.poRepository.save(po);

    const bundleSize = 50;
    const numBundles = Math.ceil(quantity / bundleSize);
    
    const bundles = [];
    for (let i = 0; i < numBundles; i++) {
      const bQty = (i === numBundles - 1 && quantity % bundleSize !== 0) 
          ? quantity % bundleSize 
          : bundleSize;
          
      const bNo = `B-${savedPo.id.split('-')[0].toUpperCase()}-${i+1}`;
      bundles.push(this.bundleRepository.create({
        bundle_no: bNo,
        barcode: bNo, // Barcode equals bundle_no for simplicity
        productionOrder: savedPo,
        quantity: bQty,
        status: BundleStatus.IN_STORE, // Starts at in_store
      }));
    }
    
    await this.bundleRepository.save(bundles);

    await this.auditService.logAction(
      'PO_CREATED',
      adminUser,
      'ProductionOrder',
      savedPo.id,
      { articleName, quantity, assignedLinemanId }
    );

    return {
      message: 'Production Order created and bundles generated successfully',
      data: savedPo
    };
  }

  async getDashboardStats() {
    const totalBundles = await this.bundleRepository.count();
    
    const pipeline = await this.bundleRepository.find({
      relations: {
        productionOrder: {
          assignedLineman: true
        }
      },
      take: 10,
      order: { created_at: 'DESC' }
    });

    const formattedPipeline = pipeline.map(b => ({
      bundleNo: b.bundle_no,
      article: b.productionOrder?.article_no,
      quantity: b.quantity,
      currentStage: b.status,
      assignedTo: b.productionOrder?.assignedLineman?.name,
    }));

    return {
      totalProduction: totalBundles * 50,
      activeLines: 14, 
      qcRejections: 0,
      pipeline: formattedPipeline
    };
  }

  async getMasterData() {
    const linemen = await this.usersService.findAllByRole(UserRole.LINEMAN);
    const articles = await this.articleRepository.find();
    
    return {
      linemen: linemen.map(l => ({ id: l.id, name: l.name })),
      articles: articles.map(a => ({ id: a.id, name: a.name, rate: a.defaultPieceRate })),
    };
  }
}
