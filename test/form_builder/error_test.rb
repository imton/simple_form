require 'test_helper'

# Tests for f.error and f.full_error
class ErrorTest < ActionView::TestCase
  def with_error_for(object, *args)
    with_concat_form_for(object) do |f|
      f.error(*args)
    end
  end

  def with_full_error_for(object, *args)
    with_concat_form_for(object) do |f|
      f.full_error(*args)
    end
  end

  test 'error should not generate content for attribute without errors' do
    with_error_for @user, :active
    assert_no_select 'span.error'
  end

  test 'error should not generate messages when object is not present' do
    with_error_for :project, :name
    assert_no_select 'span.error'
  end

  test "error should not generate messages when object doesn't respond to errors method" do
    @user.instance_eval { undef errors }
    with_error_for @user, :name
    assert_no_select 'span.error'
  end

  test 'error should generate messages for attribute with single error' do
    with_error_for @user, :name
    assert_select 'span.error', "can't be blank"
  end

  test 'error should generate messages for attribute with one error when using first' do
    swap SimpleForm, error_method: :first do
      with_error_for @user, :age
      assert_select 'span.error', 'is not a number'
    end
  end

  test 'error should generate messages for attribute with several errors when using to_sentence' do
    swap SimpleForm, error_method: :to_sentence do
      with_error_for @user, :age
      assert_select 'span.error', 'is not a number and must be greater than 18'
    end
  end

  test 'error should be able to pass html options' do
    with_error_for @user, :name, id: 'error', class: 'yay'
    assert_select 'span#error.error.yay'
  end

  test 'error should not modify the options hash' do
    options = { id: 'error', class: 'yay' }
    with_error_for @user, :name, options
    assert_select 'span#error.error.yay'
    assert_equal({ id: 'error', class: 'yay' }, options)
  end

  test 'error should find errors on attribute and association' do
    with_error_for @user, :company_id, as: :select,
      error_method: :to_sentence, reflection: Association.new(Company, :company, {})
    assert_select 'span.error', 'must be valid and company must be present'
  end

  test 'error should generate an error tag with a clean HTML' do
    with_error_for @user, :name
    assert_no_select 'span.error[error_html]'
  end

  test 'error should generate an error tag with a clean HTML when errors options are present' do
    with_error_for @user, :name, error_tag: :p, error_prefix: 'Name', error_method: :first
    assert_no_select 'p.error[error_html]'
    assert_no_select 'p.error[error_tag]'
    assert_no_select 'p.error[error_prefix]'
    assert_no_select 'p.error[error_method]'
  end

  test 'error should escape error prefix text' do
    with_error_for @user, :name, error_prefix: '<b>Name</b>'
    assert_select 'span.error', "&lt;b&gt;Name&lt;/b&gt; can't be blank"
  end

  test 'error should generate an error message with raw HTML tags' do
    with_error_for @user, :name, error_prefix: '<b>Name</b>'.html_safe
    assert_select 'span.error', "Name can't be blank"
    assert_select 'span.error b', "Name"
  end

  # FULL ERRORS

  test 'full error should generate an full error tag for the attribute' do
    with_full_error_for @user, :name
    assert_select 'span.error', "Super User Name! can't be blank"
  end

  test 'full error should generate an full error tag with a clean HTML' do
    with_full_error_for @user, :name
    assert_no_select 'span.error[error_html]'
  end

  test 'full error should allow passing options to full error tag' do
    with_full_error_for @user, :name, id: 'name_error', error_prefix: "Your name"
    assert_select 'span.error#name_error', "Your name can't be blank"
  end

  test 'full error should not modify the options hash' do
    options = { id: 'name_error' }
    with_full_error_for @user, :name, options
    assert_select 'span.error#name_error', "Super User Name! can't be blank"
    assert_equal({ id: 'name_error' }, options)
  end

  # CUSTOM WRAPPERS

  test 'error with custom wrappers works' do
    swap_wrapper do
      with_error_for @user, :name
      assert_select 'span.omg_error', "can't be blank"
    end
  end

  # FULL_ERROR_WRAPPER

  test 'full error should find errors on association' do
    swap_wrapper :default, self.custom_wrapper_with_full_error do
      with_form_for @user, :company_id, as: :select
      assert_select 'span.error', 'Company must be valid'
    end
  end

  test 'full error can be disabled' do
    swap_wrapper :default, self.custom_wrapper_with_full_error do
      with_form_for @user, :company_id, as: :select, full_error: false
      assert_no_select 'span.error'
    end
  end

  test 'full error can be disabled setting error to false' do
    swap_wrapper :default, self.custom_wrapper_with_full_error do
      with_form_for @user, :company_id, as: :select, error: false
      assert_no_select 'span.error'
    end
  end

  # CUSTOM ERRORS

  test 'input with custom error works' do
    error_text = "Super User Name! can't be blank"
    with_form_for @user, :name, error: error_text

    assert_select 'span.error', error_text
  end

  test 'input with custom error works 1' do
    with_form_for @user, :name, error: true

    assert_select 'span.error', "can't be blank"
  end

  test 'input with custom error does not generate the error if there is no error on the attribute' do
    error_text = "Super User Active! can't be blank"
    with_form_for @user, :active, error: error_text

    assert_no_select 'span.error'
  end

  test 'input with custom error works when using full_error component' do
    swap_wrapper :default, self.custom_wrapper_with_full_error do
      error_text = "Super User Name! can't be blank"
      with_form_for @user, :name, error: error_text

      assert_select 'span.error', error_text
    end
  end

  test 'input with custom error when using full_error component does not generate the error if there is no error on the attribute' do
    swap_wrapper :default, self.custom_wrapper_with_full_error do
      error_text = "Super User Active! can't be blank"
      with_form_for @user, :active, error: error_text

      assert_no_select 'span.error'
    end
  end
end
