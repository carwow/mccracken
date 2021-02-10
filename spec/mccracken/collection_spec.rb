# frozen_string_literal: true

describe McCracken::Collection do
  specify { expect(subject).to respond_to(:meta) }
  specify { expect(subject).to respond_to(:jsonapi) }
  specify { expect(subject).to respond_to(:links) }
end
