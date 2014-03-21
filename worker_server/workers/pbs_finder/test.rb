require 'yaml'
require 'test/unit'
require_relative '../pbs_finder'
require_relative 'ensembl'
require_relative 'ncbi'
require_relative 'helper'

class TestPbsFinder < Test::Unit::TestCase

  def setup
    @config = YAML.load(File.open('../../configs/pbs_finder.yml'))
    @helper = Pbs::Helper.new(@config)
  end

  def test_helper_convert_ids_genbank_to_geneid
    # Setup.
    ids = %w{ NM_001107622 NM_001013133 NM_001107645 NM_001106461 X56541 NM_030990 NM_000000000 }
    expected = [ %w{309722}, %w{306004}, %w{309922}, %w{295342}, %w{81651}, %w{24943}, [nil]]
    result = @helper.convert_ids(ids, @config[:formats][:genna], [ @config[:formats][:ezgid] ])

    # Testing.
    assert_equal(ids.size, result.size, "wrong number of ids returned")
    ids.each_with_index do |id, i|
      assert_equal(expected[i], result[id], "wrong id conversion")
    end
  end

  def test_helper_convert_ids_geneid_to_refseqrna
    # Setup.
    ids = %w{ 309722 306004 00000000 309922 295342 81651 24943 99999999 }
    expected = [%w{XM_006256352 NM_001107622}, %w{NM_001013133}, [nil],  %w{NM_001107645}, %w{XM_006233074 NM_001106461}, %w{NM_031022}, %w{NM_030990 XM_006257293}, [nil]]
    result = @helper.convert_ids(ids, @config[:formats][:ezgid], [ @config[:formats][:rseqr] ])

    # Testing.
    assert_equal(ids.size, result.size, "wrong number of ids returned")
    ids.each_with_index do |id, i|
      assert_equal(expected[i], result[id], "wrong id conversion")
    end
  end

  def test_ensembl_process_ids
    # Setup.
    ens = Pbs::Ensembl.new(@helper)
    ids = %w{ ENSRNOG00000015821 FBgn0032250 ENSRNOT00000021169 FBtr0080009 10283775 ENSRNOT99001021169 }
    expected = %w{ ENSRNOG00000015821 FBgn0032250 ENSRNOG00000015811 FBgn0051716 } + [nil, nil]
    result = ens.process_ids(ids)

    # Testing.
    assert_equal(ids.size - 1, result.size, "wrong number of conversions")
    count = 0
    ids.each_with_index do |id, i1|
      i2 = result.find_index { |x| x.original_id == id }
      if i2
        assert_equal(expected[i1], result[i2].id, "wrong conversion")
        count += 1
      end
    end
    assert_equal(ids.size - 1, count, "wrong number of conversions")
  end

  def test_helper_divide_ids
    # Setup.
    #ens = Pbs::Ensembl.new(@helper)
    #ids = %w{ ENSRNOG00000015821 FBgn0032250 ENSRNOT00000021169 FBtr0080009 10283775 ENSRNOT99001021169 }
    #result = @helper.divide_ids(ids, ens.process_ids(ids))

    # Testing.
    #assert(false, "TODO")
  end

  def test_ensembl_find_protein_binding_sites
    # Setup.
    #ens = Pbs::Ensembl.new(@helper)
    #ids = %w{ ENSRNOG00000015821 FBgn0032250 ENSRNOT00000021169 FBtr0080009 10283775 ENSRNOT99001021169 }
    #result = @helper.divide_ids(ids, ens.process_ids(ids))
    #result = ens.find_protein_binding_sites(result[:ensembl])

    # Testing.
    #assert(false, "TODO")
  end

  def test_helper_convert_ids
    # Setup.
    ids = %w{ NM_001107622 NM_001013133 NM_001107645 NM_001106461 X56541 NM_030990 NM_000000000 292588 }
    expected = [ %w{309722}, %w{306004}, %w{309922}, %w{295342}, %w{81651}, %w{24943}, [nil]]
    result = @helper.convert_ids(ids, @config[:formats][:genna], [ @config[:formats][:engid], @config[:formats][:ezgid] ])
    puts result.inspect

    # Testing.
    #assert(false, "TODO")
  end

end
