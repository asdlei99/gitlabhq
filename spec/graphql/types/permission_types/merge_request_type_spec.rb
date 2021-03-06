# frozen_string_literal: true

require 'spec_helper'

describe Types::MergeRequestType do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }
end
