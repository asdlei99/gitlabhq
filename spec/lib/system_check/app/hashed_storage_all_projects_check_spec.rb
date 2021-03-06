# frozen_string_literal: true

require 'spec_helper'
require 'rake_helper'

describe SystemCheck::App::HashedStorageAllProjectsCheck do
  before do
    silence_output
  end

  describe '#check?' do
    it 'fails when at least one project is in legacy storage' do
      create(:project, :legacy_storage)

      expect(subject.check?).to be_falsey
    end

    it 'succeeds when all projects are in hashed storage' do
      create(:project)

      expect(subject.check?).to be_truthy
    end
  end
end
