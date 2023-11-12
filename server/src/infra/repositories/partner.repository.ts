import { IPartnerRepository, PartnerIds } from '@app/domain';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Entity, Repository } from 'typeorm';
import { PartnerEntity } from '../entities';
import { ENTRY_PROVIDER_WATERMARK } from '@nestjs/common/constants';

@Injectable()
export class PartnerRepository implements IPartnerRepository {
  constructor(@InjectRepository(PartnerEntity) private readonly repository: Repository<PartnerEntity>) {}

  getAll(userId: string): Promise<PartnerEntity[]> {
    return this.repository.find({ where: [{ sharedWithId: userId }, { sharedById: userId }] });
  }

  get({ sharedWithId, sharedById }: PartnerIds): Promise<PartnerEntity | null> {
    return this.repository.findOne({ where: { sharedById, sharedWithId } });
  }

  async create({ sharedById, sharedWithId }: PartnerIds): Promise<PartnerEntity> {
    await this.repository.save({ sharedBy: { id: sharedById }, sharedWith: { id: sharedWithId } });
    return this.repository.findOneOrFail({ where: { sharedById, sharedWithId } });
  }

  async remove(entity: PartnerEntity): Promise<void> {
    await this.repository.remove(entity);
  }

  async getPartnerIds(userId: string): Promise<string[]> {
    let partnerIds: string[] = [];

    let partnerEntries: PartnerEntity[] = await this.getAll(userId);
    for (var entry of partnerEntries) {
      if (entry.sharedById != userId) {
        partnerIds.push(entry.sharedById);
      }
      if (entry.sharedWithId != userId) {
        partnerIds.push(entry.sharedWithId);
      }
    }

    return partnerIds;
  }
}
